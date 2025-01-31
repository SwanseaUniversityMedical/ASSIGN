# ASSIGN-container

Repo to allow easy deployment of ASSIGN (https://github.com/endeavourhealth-discovery/ASSIGN) via a docker container. 

Dockerfile creates an image with YottaDB set up for running the ASSIGN code.

On `docker run` it will ask the user for the repo URL, installation path, and commit sha for the repo. Defaults are provided:
* `assign_url="https://github.com/endeavourhealth-discovery/ASSIGN.git"`
* `assign_dest="./ASSIGN"`
* `sha=""`

The default for sha provides the current master head of the repo. 

Example:
```
Enter ASSIGN git repo url (https://github.com/endeavourhealth-discovery/ASSIGN.git):
Enter ASSIGN install path (./ASSIGN):
Enter ASSIGN commit sha ( ):
Cloning into './ASSIGN'... 
```

## Usage
When running the container, be sure to provide `docker run` with the following:
* A port for the YottaDB GUI if you wish to access it from localhost.
* A volume containing processed ABP csv files, which is then mounted to the container at `/data/ABP`. As a minimum, ASSIGN currently requires the following ABP files:
  * __ID32_Class_Records.csv__
  * __ID28_DPA_Records.csv__
  * __ID24_LPI_Records.csv__
  * __ID21_BLPU_Records.csv__
  * __ID15_StreetDesc_Records.csv__

Once in the container you will be at the YottaDB terminal. Load ABP into the database with `d ^UPRN1A`, you will then need to provide the path to the ABP data and confirm the load type:
```
YDB>d ^UPRN1A

ABP folder () :/data/ABP

Full, addtional  or delta upload (F/D/A) ? :F

You are about to delete the ABP data and replace it

Are you sure you wish to proceeed !!?y
```

This should then process ABP and ingest it into the appropriate globals for the ASSIGN routines to query.

## What deployment looks like
A docker container running the yottaDB spun up. 
Then responsible dev shells into container to import the ABP as above. 
This container runs a web service listening for a TCP request. This request then uses the underlying mumps routine to query ASSIGN and provide the JSON response.

Set up a container with a simple web server which allows a user to log in and make a request over TCP, this allows us to control routes of access via network rules.
