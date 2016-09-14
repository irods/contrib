#!/bin/bash

export HOME=/var/lib/nagios

echo update_irods_resc_state "$@" >> /tmp/update_resc.log

#export IRODS_HOST=localhost
HOST=$1
SERVICE_STATE=$2
SERVICE_STATE_TYPE=$3
SERVICE_ATTEMPT=$4

RESOURCES=$(iquest "%s" "select RESC_NAME where RESC_LOC = '$HOST'")

echo RESOURCES = $RESOURCES >> /tmp/update_resc.log
echo SERVICES_STATE = $SERVICE_STATE >> /tmp/update_resc.log


case "$SERVICE_STATE" in
OK)
    for RESOURCE in $RESOURCES; do
        iadmin modresc $RESOURCE status up
    done
    ;;
WARNING)
    ;;
UNKNOWN)
    ;;
CRITICAL)
    for RESOURCE in $RESOURCES; do
        iadmin modresc $RESOURCE status down
    done
    ;;

esac
exit 0

