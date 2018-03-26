#!/bin/bash

# genresp.sh
# Generates responses for iRODS' setup_irods.py script.

RESPFILE=$1

# Setup service account
echo "$UID" > $RESPFILE                   # service account user ID
echo "$GID" >> $RESPFILE                  # service account group ID
echo "$ROLE" >> $RESPFILE                 # iRODS server's role: provider[1] or consumer[2]

# Configure database communication
if [[ "$ROLE" == 1 ]]; then
  echo "$OBDC_DRIVER" >> $RESPFILE          # ODBC driver for postgres: PostgreSQL ANSI [1] or PostgreSQL Unicode [2]
  echo "$DB_HOST" >> $RESPFILE              # database hostname
  echo "$DB_PORT" >> $RESPFILE              # database port
  echo "$DB_NAME" >> $RESPFILE              # database DB name
  echo "$DB_USR" >> $RESPFILE               # database admin username
  echo "yes" >> $RESPFILE                   # confirm database settings
  echo "$DB_PSWD" >> $RESPFILE              # database admin password
  echo "$DB_PSWD_SALT" >> $RESPFILE         # database password salt
fi

#Configure server options
echo "$ZONE" >> $RESPFILE                 # initial zone name
if [[ "$ROLE" == 2 ]]; then
  echo "$ICAT_HOST" >> $RESPFILE            # iRods catalog host
fi
echo "$ZONE_PORT" >> $RESPFILE            # service port
echo "$PARALLEL_PORT_START" >> $RESPFILE  # transport starting port
echo "$PARALLEL_PORT_END" >> $RESPFILE    # transport ending port
echo "$CONTROL_PLANE_PORT" >> $RESPFILE	  # control plane port
echo "$VALIDATION_URI" >> $RESPFILE       # schema validation URI
echo "$IRODS_ADMIN" >> $RESPFILE          # iRODS admin account
echo "yes" >> $RESPFILE                   # confirm server settings

# Configure keys and passwords
echo "$ZONE_KEY" >> $RESPFILE             # iRODS zone key
echo "$NEGOTIATION_KEY" >> $RESPFILE      # Zone negotiation key
echo "$CONTROL_PLANE_KEY" >> $RESPFILE    # Control plane key
echo "$IRODS_PSWD" >> $RESPFILE           # iRODS admin password
# Vault directory
echo "$VAULT_PATH" >> $RESPFILE           # Vault path

