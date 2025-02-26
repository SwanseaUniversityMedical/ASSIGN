ARG YDB_VERSION="r2.01"

FROM yottadb/yottadb:${YDB_VERSION}

LABEL org.opencontainers.image.source=https://github.com/SwanseaUniversityMedical/ASSIGN-container

#USER root
SHELL ["/bin/bash", "-c"]

# Get git.
RUN apt-get update && apt-get install -y git

# ASSIGN install env vars
ENV assign_url="https://github.com/endeavourhealth-discovery/ASSIGN.git"
ENV assign_dest="/data/ASSIGN"
ENV assign_sha=""
ENV abp_dir="/data/ABP"
ENV abp_checkfile="$abp_dir/abp_checkfile"
ENV trigger_abp_load="false"
ENV start_assign="true"

# YDB env vars
ARG YDB_VERSION
ENV ydb_chset="M"
ENV ydb_dir="/data"
ENV ydb_rel="${YDB_VERSION}_x86_64"

# Create directory to hold ABP
RUN mkdir -p $abp_dir

# Yotta TLS setup
RUN apt-get update && \
    apt-get install -y make curl wget gcc libgcrypt-dev libssl-dev libgpgme-dev libconfig-dev tcsh && \
    /opt/yottadb/current/ydbinstall --plugins-only --encplugin

# Placeholder for testing only
ENV USER=root
#ENV cert_pass="monkey1234"
#ENV cert_subj="/C=US/ST=Washington/L=Seattle/CN=www.smh101.com"
#ENV cert_dir="/data/certs"

#RUN mkdir -p $cert_dir &&\
#    openssl genrsa -aes128 -passout pass:$cert_pass -out $cert_dir/mycert.key 2048 && \
#    openssl req -new -key $cert_dir/mycert.key -passin pass:$cert_pass -subj $cert_subj -out $cert_dir/mycert.csr && \
#    openssl req -x509 -days 365 -sha256 -in $cert_dir/mycert.csr -key $cert_dir/mycert.key -passin pass:$cert_pass -out $cert_dir/mycert.pem

#COPY certs/ydb_crypt_config.libconfig $cert_dir/ydb_crypt_config.libconfig
#ENV ydb_crypt_config="$cert_dir/ydb_crypt_config.libconfig"

# Add in startup script.
COPY startup_scripts/assign-startup.sh /assign-startup.sh
RUN chmod +x /assign-startup.sh

# Add in web auth
COPY startup_scripts/ADDWEBAUTH.m /extra_scripts/ADDWEBAUTH.m
RUN chmod 644 /extra_scripts/ADDWEBAUTH.m

# Expose port for YottaDB GUI
EXPOSE 9080
EXPOSE 9081

ENTRYPOINT ["/assign-startup.sh"]