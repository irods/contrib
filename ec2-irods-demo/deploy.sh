#!/bin/bash

# deploy.sh
# Deploys iRODS and iDrop Web to an Amazon Machine Image. Includes per-instance script
# to generate random password for iRODS administrator account (i.e., rods).

IRODS_FOLDER=$1
IRODS_VERSION=$2
DB_PLUGIN_FOLDER=$3
DB_PLUGIN_VERSION=$4

sudo cp ./per-instance/* /var/lib/cloud/scripts/per-instance
cd ./per-once
./build.sh $IRODS_FOLDER $IRODS_VERSION $DB_PLUGIN_FOLDER $DB_PLUGIN_VERSION > build.sh.out
