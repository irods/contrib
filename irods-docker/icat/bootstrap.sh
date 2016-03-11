#!/bin/bash
RODS_PASSWORD=$1


# Wait for progres
sleep 5

# Grab postgres env: should pass properly in docker compose
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

# Only generate the setup_responses file if it does not exist
if [ ! -s /export/etc/irods/setup_responses ]; then
    # generate configuration responses
    /opt/irods/genresp.sh /etc/irods/setup_responses
    if [ -n "$RODS_PASSWORD" ]
      then
        sed -i "14s/.*/$RODS_PASSWORD/" /etc/irods/setup_responses
    fi
fi

# Not sure if this is neccesary
#if [ -s /export/var/lib/irods/.irods/.irodsEnv ]; then
#    sed -i 's/^irodsHost.*/irodsHost localhost/' /var/lib/irods/.irods/.irodsEnv
#
#fi
# Copy & rm then link folders in export, need to add option for files
if [ -d /export ]; then
    if [ ! -s /export/.export ]; then
        cp /.export /export/.export
    fi
    while read f; do

        if [ ! -d ${f} ]; then
            mkdir -p /export${f}
        else
            rsync --ignore-existing -prRALE ${f} /export
            rm -rf ${f}
        fi
        chown -R 999:999 /export${f}
        ln -s /export${f} ${f}
    done </export/.export
fi

# Delete the service_account.config file so irods creates the irods user
if [ -e /etc/irods/service_account.config ]; then
    rm -f /etc/irods/service_account.config
fi
# set up PAM auth
source /opt/irods/pam.sh
# set up the iCAT database
/opt/irods/setupdb.sh /etc/irods/setup_responses
# set up iRODS
/opt/irods/config.sh /etc/irods/setup_responses
# this script must end with a persistent foreground process
tail -f /var/lib/irods/iRODS/server/log/rodsLog.*
#sleep infinity
