#!/bin/bash
RODS_PASSWORD=$1

# generate configuration responses
/opt/irods/genresp.sh /opt/irods/setup_responses

if [ -n "$RODS_PASSWORD" ]
  then
    sed -i "14s/.*/$RODS_PASSWORD/" /opt/irods/setup_responses
fi

if [ -z "$POSTGRES_SERVER" ]
  then
    export POSTGRES_SERVER="localhost"
fi

if [ -z "$POSTGRES_PASSWORD" ]
  then
    export POSTGRES_PASSWORD="mysecretpassword"
fi

if [ -z "$POSTGRES_USER" ]
  then
    export POSTGRES_USER="irods"
fi

if [ -z "$POSTGRES_DB" ]
  then
    export POSTGRES_DB="ICAT"
fi

# set up the iCAT database
service postgresql start
/opt/irods/setupdb.sh /opt/irods/setup_responses
# set up iRODS
/opt/irods/config.sh /opt/irods/setup_responses
#change irods user's irodsEnv file to point to localhost, since it was configured with a transient Docker container's $
sed -i 's/^irodsHost.*/irodsHost localhost/' /var/lib/irods/.irods/.irodsEnv
# this script must end with a persistent foreground process
#tail -f /var/lib/irods/iRODS/server/log/rodsLog.*
sleep infinity
