#!/bin/bash

# setupdb.sh
# Sets up a Postgres database for iRODS by creating a database and user and granting
# privileges to the user.

if [ $LOCALDB == "true" ] ; then
    DEBIAN_FRONTEND=noninteractive;
    sudo apt-get install -y postgresql;
    sudo service postgresql restart
    sudo -u postgres createdb -O postgres 'ICAT' && \
    sudo -u postgres psql -U postgres -d postgres -c "CREATE USER $DB_USR WITH PASSWORD '$DB_PSWD'" && \
    sudo -u postgres psql -U postgres -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"ICAT\" TO $DB_USR"
else
    echo "database set to external"
fi

