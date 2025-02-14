#!/bin/bash

mkdir -p /data/logs

# Check if database file exists, if so try a rundown incase it was borked by container stopping
if [ -f "$ydb_dir/$ydb_rel/g/yottadb.gld" ]; then
  echo "Running rundown to restore database."
  export ydb_gbldir="$ydb_dir/$ydb_rel/g/yottadb.gld"
  /opt/yottadb/current/mupip rundown -region DEFAULT
fi

# Check if env vars need setting (not ideal, but better than checking every one
if [ -z "${ydb_dist}" ]; then
  echo "ydb_dist not set. Setting variables."
  . /opt/yottadb/current/ydb_env_set
else
  echo "ydb_dist already set. Not setting variables again."
fi

# Check if ASSIGN needs pulling
if [ "$assign_sha" == "" ]; then
  echo "Given sha was empty, using HEAD of $assign_url."
  assign_sha=$(git ls-remote $assign_url HEAD | cut -f1 | cut -c1-7)
  echo "New value for assign_sha is $assign_sha. Matching remote HEAD sha."
fi

if [[ -d "$assign_dest" && "${assign_sha::7}" == $(git -C $assign_dest rev-parse --short HEAD) ]]; then
  # Exists and matches
  echo "Previous ASSIGN installation found matching current sha. No need to change ASSIGN."
else

  # Check if exists, get it if not
  if [ ! -d "$assign_dest" ]; then
    echo "ASSIGN not previously installed. Obtaining ASSIGN routines." && git clone $assign_url $assign_dest
    # Set flag to trigger ABP reload
    reload_abp=true
  else
    # Get current sha
    cur_sha=$(git -C $assign_dest rev-parse --short HEAD)

    # Check if wanted sha exists in current clone
    echo "Current version of sha does not match that requested. Will re-install ASSIGN."
    echo "Checking if wanted sha exists in current clone of repo."
    if ! git -C $assign_dest cat-file -e $assign_sha^{commit}; then
      echo "sha not found, pulling remote." && git -C $assign_dest reset --hard origin/master && git -C $assign_dest clean -fxd && git -C $assign_dest pull
    else
      echo "sha $assign_sha found, no need to pull."
    fi

    # Set flag to trigger ABP reload
    if ! git -C $assign_dest diff --quiet $cur_sha $assign_sha -- $assign_dest/UPRN/yottadb/UPRN1A.m || ! git -C $assign_dest diff --quiet $cur_sha $assign_sha -- $assign_dest/UPRN/yottadb/UPRNIND.m ; then
      echo "Import mumps code has changed, setting flag to trigger reload."
      reload_abp=true
    else
      reload_abp=false
    fi
  fi

  # Checkout the wanted sha
  echo "Checking out $assign_sha."
  git -C $assign_dest checkout $assign_sha

  # Put the routines to the YottaDB routines directory
  echo "Moving the routines."
  cp $assign_dest/UPRN/yottadb/* $ydb_dir/$ydb_rel/r
  cp $assign_dest/UPRN/codelists/* $abp_dir

  # Remove previous checks to trigger the reload later # Change on UPRN1A UPRNIND triggers the reload
  if [ "$reload_abp" == "true" ]; then
    echo "Removing old check files."; [ -e $abp_checksum ] && rm $abp_checksum; [ -e $ydb_checkfile ] && rm $ydb_checkfile
  fi
fi

# Perform zlink of routines, doesn't matter if already linked
echo "Linking ASSIGN routines, you may see warnings."
$ydb_dist/ydb -run ^ZLINK
echo "Routines linked."

# Update YottaDB database settings
$ydb_dist/mupip set -NULL_SUBSCRIPTS=true -region DEFAULT && \
$ydb_dist/mupip set -extension_count=500000 -region DEFAULT && \
$ydb_dist/mupip set -journal=off -region DEFAULT #&& \
#$ydb_dist/mupip set -access_method=mm -region DEFAULT

# Check if data needs loading
function calc_abp_checksum { sha256sum $abp_dir/* | sha256sum | awk '{ print $1 }'; }

function load_abp_to_assign {
  # Remove previous checks to trigger the reload later
  echo "Removing old check files."; [ -e $abp_checksum ] && rm $abp_checksum; [ -e $ydb_checkfile ] && rm $ydb_checkfile

  # Reload
  echo "Importing ABP from $abp_dir." && $ydb_dist/ydb -run %XCMD 'd IMPORT^UPRN1A("/data/ABP")'
  echo "Ingest okay. Producing checkfile for ABP load." && echo $(date +%Y_%m_%d) > $ydb_checkfile && \
  echo "Producing checksum for $abp_dir." && calc_abp_checksum > $abp_checksum
  }

{
# If either ABP checksum or YDB checksum are missing then we presume data hasn't been loaded previously.
if [[ ! -f "$abp_checksum" || ! -f "$ydb_checkfile" ]]; then
  if [ ! -f "$abp_checksum" ]; then echo "$abp_checksum is missing."; fi
  if [ ! -f "$ydb_checkfile" ]; then echo "$ydb_checkfile is missing."; fi
  echo "Reload of ABP needed. Reloading data."
  load_abp_to_assign
# else if the checksums don't match...
elif [[ $(cat $abp_checksum) != $(calc_abp_checksum) ]]; then
  echo "Prev ABP checksum: $(cat $abp_checksum)\nCurr ABP checksum: $(calc_abp_checksum)"
  echo "ABP checksum does not match. Reloading data."
  load_abp_to_assign
# else they match
else
  echo "Data checks match, no need to reload."
fi

# Set the ybd env var for the TLS password hash, this can be replaced with an ENV var in the image?
#export ydb_tls_passwd_dev="$($ydb_dist/plugin/ydbcrypt/maskpass <<< $cert_pass | cut -d ":" -f2 | tr -d ' ')"

# Startup the ASSIGN TLS listener
echo "Starting listener"
yottadb -run %XCMD 'job START^VPRJREQ(9081)' &

# Startup the ASSIGN web API interface
echo "Starting ASSIGN API endpoints"
cp "/extra_scripts/ADDWEBAUTH.m" "$ydb_dir/$ydb_rel/r/ADDWEBAUTH.m"
yottadb -run INT^VUE          # File upload/download
yottadb -run SETUP^UPRNHOOK2  # UPRN retrieval
yottadb -run ^NEL             # request handling
yottadb -run ^ADDWEBAUTH      # Add creds
} &

# Startup webgui.
echo "Starting YottaDB GUI endpoint"
yottadb -run %ydbgui --readwrite --port 9080 >> /data/logs/%ydbgui.log
