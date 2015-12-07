#!/bin/bash

# 50-configure.sh

# variables
RESPFILE="/opt/ec2-irods-demo/setup_responses"
DATABASE_NAME="ICAT"
DATABASE_USER="irods"
EC2_INSTANCE_ID=$(ec2metadata --instance-id)

get_random_string() {
    # $1 is used if passed in, otherwise use default
    RANDOM_STRING_LENGTH=$1
    if [ "$RANDOM_STRING_LENGTH" == "" ] ; then
        RANDOM_STRING_LENGTH="16"
    fi
    RANDOM_STRING=`openssl rand -base64 $RANDOM_STRING_LENGTH | sed 's,/,S,g' | sed 's,+,_,g' | cut -c 1-$RANDOM_STRING_LENGTH`
}


# Generates responses for iRODS' setup_irods.sh script.
#
# Randomized:
#  zone_key
#  negotiation_key
#  control_plane_key
#  iRODS admin password
#  database admin

echo "irods" > $RESPFILE                                       # service account user name
echo "irods" >> $RESPFILE                                      # service account group name
echo "tempZone" >> $RESPFILE                                   # initial zone name
echo "1247" >> $RESPFILE                                       # iRODS port
echo "20000" >> $RESPFILE                                      # parallel transport begin port
echo "20199" >> $RESPFILE                                      # parallel transport ending port
echo "/var/lib/irods/Vault" >> $RESPFILE                       # vault path
get_random_string 16 ; echo $RANDOM_STRING >> $RESPFILE        # zone_key
get_random_string 32 ; echo $RANDOM_STRING >> $RESPFILE        # negotiation_key
echo "1248" >> $RESPFILE                                       # control plane port
get_random_string 32 ; echo $RANDOM_STRING >> $RESPFILE        # control plane key
echo "https://schemas.irods.org/configuration" >> $RESPFILE    # schema validation URI
echo "rods" >> $RESPFILE                                       # iRODS admin account
echo $EC2_INSTANCE_ID >> $RESPFILE                             # iRODS admin password
echo "yes" >> $RESPFILE                                        # confirm iRODS settings
echo "localhost" >> $RESPFILE                                  # database hostname
echo "5432" >> $RESPFILE                                       # database port
echo $DATABASE_NAME >> $RESPFILE                               # database name
echo $DATABASE_USER >> $RESPFILE                               # database admin username
echo $EC2_INSTANCE_ID >> $RESPFILE                             # database admin password
echo "yes" >> $RESPFILE                                        # confirm database settings


# Creates a database for iRODS to use:
#  - creates database
#  - creates user role with password
#  - grants privileges

sudo -u postgres psql -U postgres -d postgres -c "CREATE DATABASE \"$DATABASE_NAME\""
sudo -u postgres psql -U postgres -d postgres -c "CREATE USER $DATABASE_USER WITH PASSWORD '$EC2_INSTANCE_ID'"
sudo -u postgres psql -U postgres -d postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"$DATABASE_NAME\" TO $DATABASE_USER"

# Set hostname
FQDN_LOCATION="/var/tmp/FQDN"
export FQDN=$(ec2metadata --public-hostname)
sudo hostname $FQDN
echo $FQDN > /etc/hostname
sudo su -c "echo $FQDN > $FQDN_LOCATION"

# Configure iRODS
sudo su -c "/var/lib/irods/packaging/setup_irods.sh < $RESPFILE"

# Restart apache
sudo service apache2 restart
