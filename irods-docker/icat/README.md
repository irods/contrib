# docker-iRODS-iCAT

The docker iRODS iCAT Image is an easy distributable, core iRODS deployment. It can be used for testing, teaching and production.

This image runs a self-contained iRODS server and postgresql database.

## Configuration
The following options can be set as environmental values on startup:

##### Service account options
| parameter  | default | synopsis       |
|--------|---------|----------------|
|UID|rods| iRODS system user id  |
|GID|rods|iRODS system group id|
|ROLE|1|iRODS server's role: provider [1] or consumer [2]|

##### Database options
| parameter  | default | synopsis       |
|--------|---------|----------------|
|LOCALDB|true|use a local (in-docker) postgresql database (true/false)|
|OBDC_DRIVER|1|ODBC driver for postgres: PostgreSQL ANSI [1] or PostgreSQL Unicode [2]|
|DB_HOST|127.0.0.1|database host (FQDN)|
|DB_PORT|5432| database port|
|DB_NAME|ICAT| database name|
|DB_USR|irods| database user |
|DB_PSWD|rodspswd|  database user password |
|DB_PSWD_SALT|RandomStringToHash| random string to salt passwords |

##### Server options
| parameter  | default | synopsis       |
|--------|---------|----------------|
|ZONE|tempZone|iRODS zone name |
|ICAT_HOST|empty| Mandatory, but only used when ROLE is consumer [2], FQDN of iRODS server to connect to |
|ZONE_PORT|1247|main connection port|
|PARALLEL_PORT_START|20000|connection port range for parallel transfers (start)|
|PARALLEL_PORT_END|20199|connection port range for parallel transfers (end)|
|VALIDATION_URI|https://schemas.irods.org/configuration|template for database scheme|
|IRODS_ADMIN|rods| iRODS admin user  |

##### Keys and Passwords
| parameter  | default | synopsis       |
|--------|---------|----------------|
|ZONE_KEY|TEMPORARY_zone_key|zone authentication key, used for communication between zones, can be up to 49 alphanumeric characters long and cannot include a hyphen|
|NEGOTIATION_KEY|TEMPORARY_32byte_negotiation_key|zone negotiation key, must be exactly 32 alphanumeric bytes long, and the same across zones|
|CONTROL_PLANE_PORT|1248|iRODS control plane port|
|CONTROL_PLANE_KEY|TEMPORARY__32byte_ctrl_plane_key|control plane authentication key|
|IRODS_PSWD|rodspswd| iRODS admin password  |

##### Vault options
| parameter  | default | synopsis       |
|--------|---------|----------------|
|VAULT_PATH|/var/lib/irods/Vault|default directory where data will be stored|


## Usage

### Build image
```
cd icat && \
docker build -t irods/icat:4.2.0 --rm .
```

### Run image
To run this docker image, simply do
```
docker run -d -p 1247:1247 irods/icat:4.2.0
```
This will create an empty iRODS repository, which connects to the internal database. Without further configuration, all data will be stored inside the docker image in `$VAULT_PATH`.
Please note that ALL DATA in this setup is NON PERSISTENT. This means that once the image is removed, all data and database will be lost.

If all default parameters are used, all files will be stored in `/export/Vault`.
To mount the `/export` directory, start the image with
```
docker run -d -p 1247:1247 -v /your/irods/data/dir/:/export irods/icat:4.2.0
```

### Configuring the image for production

1. Set up an external database.

Set up and configure an external database for your iRODS instance. You can do this by executing:
```
sudo apt-get install -y postgresql
sudo -u postgres createdb -O postgres 'ICAT' && \
sudo -u postgres psql -U postgres -d postgres -c "CREATE USER $DB_USR WITH PASSWORD '$DB_PSWD'" && \
sudo -u postgres psql -U postgres -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"ICAT\" TO $DB_USR"
```

2. Configure iRODS

To configure this image for production use first start the iRODS image with the correct parameters if they are different from the default values
```
docker run -d -p 1247:1247 \
-e ZONE=yourZoneName \
-e LOCALDB=false \
-e DB_HOST=FQDN.FOR.YOUR.DB \
-e DB_PORT=5432 \
-e DB_NAME=ICAT \
-e DB_USR=irods \
-e DB_PSWD=rodspswd \
irods/icat:4.2.0
```
Random keys can be generated with:
```
openssl rand -base64 $key_length
```
More configurable parameters are listed above

Next, install the `icommands` suite from https://irods.org/download/ and connect to your iRODS instance using the `iinit` command.
Your iRODS instance is now fully configurable using `icommands`. Add extra resources and you're good to go. For more information on configuring iRODS, go to https://docs.irods.org

Typically, an iRODS instance gets started with the command above, after which production ready storage should be added. This can be done by mounting a volume to the docker image in an arbitrary folder and add this folder as a resource. Alternatively, storage can be added through an Amazon S3 gateway, or other options. For more info, see https://docs.irods.org


NOTE: This image does NOT support linked containers.


