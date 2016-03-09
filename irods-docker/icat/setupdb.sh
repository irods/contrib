#!/bin/bash

# setupdb.sh
# Sets up a Postgres database for iRODS by creating a database and user and granting
# privileges to the user.

RESPFILE=$1
DBUSER=`tail -n 3 $RESPFILE | head -n 1`
DBPASS=`tail -n 2 $RESPFILE | head -n 1`

createdb -h $POSTGRES_SERVER -O postgres -U postgres 'ICAT'
psql -h $POSTGRES_SERVER -U postgres -d postgres -c "CREATE USER $DBUSER WITH PASSWORD '$DBPASS'"
psql -h $POSTGRES_SERVER -U postgres -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"ICAT\" TO $DBUSER"
