#!/bin/bash

# generate configuration responses
/opt/irods/genresp.sh /opt/irods/setup_responses

# set up the iCAT database
/opt/irods/setupdb.sh

# set up iRODS
python /var/lib/irods/scripts/setup_irods.py < /opt/irods/setup_responses

#change irods user's irodsEnv file to point to localhost, since it was configured with a transient Docker container's $
sed -i 's~"irods_host":.*~"irods_host": "localhost",~g' /var/lib/irods/.irods/irods_environment.json

# this script must end with a persistent foreground process
tail -f /var/lib/irods/log/rodsLog*
#sleep infinity
