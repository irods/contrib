#!/bin/bash

# fail on uninitialized vars rather than treating them as null
set -u
# fail on the first program that returns $? != 0
set -e

# setupdb.sh
# Sets up a Postgres database for iRODS by creating a database and user and granting
# privileges to the user.

RESPFILE=$1
DBUSER=`tail -n 3 $RESPFILE | head -n 1`
DBPASS=`tail -n 2 $RESPFILE | head -n 1`

PSQL=( psql  -U postgres -d postgres -h ${POSTGRES_SERVER} -v ON_ERROR_STOP=1 )

# Create icat database if not existing
if ! ${PSQL[@]} -lqt | cut -d \| -f 1 | grep -qw ICAT >> /dev/null 2>&1  ; then
    createdb -h $POSTGRES_SERVER -O postgres -U postgres 'ICAT'
fi

# Create or update irods postgres user
${PSQL[@]} << EOSQL
    DO
    \$body\$
    BEGIN
        IF NOT EXISTS (
            SELECT *
            FROM   pg_catalog.pg_user
            WHERE  usename = '${DBUSER}') THEN

            CREATE ROLE ${DBUSER} LOGIN PASSWORD '${DBPASS}';
            GRANT ALL PRIVILEGES ON DATABASE "ICAT" TO ${DBUSER};
        ELSE
            ALTER USER ${DBUSER} WITH PASSWORD '${DBPASS}';
        END IF;
    END
    \$body\$;
EOSQL
