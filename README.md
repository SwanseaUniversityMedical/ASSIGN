# ASSIGN-container

Repo to allow easy deployment of ASSIGN (https://github.com/endeavourhealth-discovery/ASSIGN) via a docker container. 

Dockerfile creates an image with YottaDB set up for running the ASSIGN code and querying via api endpoint. 

## Building the container
Usual `docker build` applies:

`$ docker build -t <name>:<tag> -f ./containers/assign/Dockerfile .`

There is an optional argument for `YDB_VERSION` which can allow the built image to use a different [image of YottaDB](https://hub.docker.com/r/yottadb/yottadb). 
The default is `r2.01`. To change in the build process:

`$ docker build --buld-arg YDB_VERSION=r2.01 -t <name>:<tag> -f ./containers/assign/Dockerfile .`

## Providing address data
The container requires the [ABP](https://www.ordnancesurvey.co.uk/products/addressbase-premium) data to be provided for import to the yotta database. 
You must provide a volume containing the processed ABP csv files, which are then mounted to the container at `/data/ABP`. 
At a minimum, ASSIGN currently requires the following ABP files:
  * __ID32_Class_Records.csv__
  * __ID28_DPA_Records.csv__
  * __ID24_LPI_Records.csv__
  * __ID21_BLPU_Records.csv__
  * __ID15_StreetDesc_Records.csv__

## Installing ASSIGN
The container's startup script automatically installs the ASSIGN routines. 
By default, the container uses the version of [ASSIGN](https://github.com/endeavourhealth-discovery/ASSIGN.git) available in the latest commit master.

An environment vairable `assign_sha` is provided, defining which version of ASSIGN to use. 
The default `''` is expanded out to be the remote HEAD commit.
A wanted sha can be provided by setting the `assign_sha` at run time, either long or short form.

## Running the container
To run the container with the latest version of ASSIGN:

`docker run -v <local_abp_dir>:/data/ABP <name>:<tag>`

 To specify a version of ASSIGN to install, provide the commit SHA via the environment variable `assign_sha`:

`docker run -e assign_sha=<sha> -v <local_abp_dir>:/data/ABP <name>:<tag>`


## Running the container with `docker compose`
A docker compose is also provided, detailing volumes, ports, and the ASSIGN sha.

## Usage
On startup, the container will check to see if ASSIGN is present or the versions differ. 
It will then pull down ASSIGN if needed and install the appropriate routines.

It will check to see if ABP has been loaded before, or if the data has changed.
If needed, it will begin loading ABP into the yotta database with the ASSIGN routine `d IMPORT^UPRN1A("/data/ABP")`.
This step may take some time, but once complete it will create checksums for `/data/ABP` and the yotta database.

Finally, it will start up two web services.
* ASSIGN API endpoint, so that address strings can be queried via web requests.
* YottaDB GUI, for database monitoring. 

Monitor the ABP import, and once complete you should be able to query address strings against the database using the installed version of ASSIGN.