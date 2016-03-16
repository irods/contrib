#!/usr/bin/env bash

# upgrade.sh
# Determines if ICAT needs to be upgraded from a previous version
#

VERSIONFILE=$1
UPGRADE=( /var/lib/irods/packaging/build.sh --run-in-place icat postgres )

if [ -s $VERSIONFILE ]; then
    read -a ver < ${VERSIONFILE}
    if [ "${IRODS_VERSION}" -ne ${ver[0]} ] &&  [ "${ICAT_PLUGIN}" -ne ${ver[1]} ]; then
        ${UPGRADE[@]}
    fi
else
    ${UPGRADE[@]}
fi