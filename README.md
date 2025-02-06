# ASSIGN-container

Repo to allow easy deployment of [ASSIGN](https://github.com/endeavourhealth-discovery/ASSIGN) via a docker container. 

Dockerfile creates an image with YottaDB set up for running the ASSIGN code and querying via api endpoint. 
___

## Building the container
Usual `docker build` applies:

`$ docker build -t <name>:<tag> -f ./containers/assign/Dockerfile .`

There is an optional argument for `YDB_VERSION` which can allow the built image to use a different [image of YottaDB](https://hub.docker.com/r/yottadb/yottadb). 
The default is `r2.01`. To change in the build process:

`$ docker build --buld-arg YDB_VERSION=r2.01 -t <name>:<tag> -f ./containers/assign/Dockerfile .`
___

## Providing address data
The container requires the [ABP](https://www.ordnancesurvey.co.uk/products/addressbase-premium) data to be provided for import to the yotta database. 
You must provide a volume containing the processed ABP csv files, which are then mounted to the container at `/data/ABP`. 
At a minimum, ASSIGN currently requires the following ABP files:
  * __ID32_Class_Records.csv__
  * __ID28_DPA_Records.csv__
  * __ID24_LPI_Records.csv__
  * __ID21_BLPU_Records.csv__
  * __ID15_StreetDesc_Records.csv__
___

## Installing ASSIGN
The container's startup script automatically installs the ASSIGN routines. 
By default, the container uses the version of [ASSIGN](https://github.com/endeavourhealth-discovery/ASSIGN.git) available in the latest commit master.

An environment vairable `assign_sha` is provided, defining which version of ASSIGN to use. 
The default `''` is expanded out to be the remote HEAD commit.
A wanted sha can be provided by setting the `assign_sha` at run time, either long or short form.
___

## Running the container
To run the container with the latest version of ASSIGN:

`docker run -v <local_abp_dir>:/data/ABP <name>:<tag>`

 To specify a version of ASSIGN to install, provide the commit SHA via the environment variable `assign_sha`:

`docker run -e assign_sha=<sha> -v <local_abp_dir>:/data/ABP <name>:<tag>`
___

## Running the container with `docker compose`
A docker compose is also provided, detailing volumes, ports, and the ASSIGN sha.
___

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
___

## Querying the endpoint
The ASSIGN API is exposed on port 9080 by default, and can be queried by simple web request.
The API provides both single query and batch processing.

For single queries we can search using:
* `getinfo` - single query. Input: address string, Return: json-encoded ASSIGN match response.
* `getuprn` - single query. Input: UPRN, Return: json-encoded ASSIGN match response.

For batch processing we use an upload and download functionality:
* `fileupload2` - batch upload. Input: TSV file where rows consist of `<id>\t<address_string>` pairs. 
* `filedownload2` - batch download. Return: txt file containing list of json-encoded ASSIGN match responses.
___

### Single queries can be carried out as follows:

`curl --user user <endpoint>/api2/getinfo?adrec=<address_string>`

where `<address_string>` is a URL-encoded address string to query, e.g.:

`curl --user user <endpoint>/api2/getinfo?adrec=10+Downing+St,London,SW1A+2AA`

Or to query UPRN numbers:

`curl --user user <endpoint>/api2/getuprn?uprn=<uprn>`

`curl --user user <endpoint>/api2/getuprn?uprn=100023336956`
___

### Batch processing can be carried out as follows:
Given an example input file with a .txt extension (`test_in.txt`), containing a tab separated, newline delimited list of (`id` `address_string`) pairs:

| 1   | 10 Downing St,London,SW1A 2AA                     |
|:---|:---|
| 2   | Swansea Univeristy,Singleton Park,Swansea,SA2 8PP |

Upload a batch file to the contain via the api:

`curl -u user -i -X POST -F "file=@<path/to/test_in.txt>" <endpoint>/api2/fileupload2`

Wait for the file to be processed, and then we can download the result via:

`curl -u user <endpoint>/api2/download3?filename=<test_in.txt> --output <path/to/test_out.txt>`
___