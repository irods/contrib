#!/bin/bash -e

####################################################################
#  This script:
#  - uses ldapsearch to query the LDAP or AD service for active usernames
#  - foreach username, confirms that user exists in iRODS
#  - creates any users that are missing
#
#  Configure to run in cron (perhaps daily):
#  root# crontab -l
#  0 6 * * * su zoneadminserviceaccount -c "/var/lib/irods/sync_ad_accounts.sh >> /var/lib/irods/sync_ad_accounts.log"
#
#  Results:
#  root# tail /var/lib/irods/sync_ad_accounts.log
#  Tue Nov 15 06:00:02 EST 2016
#  Wed Nov 16 06:00:01 EST 2016
#  Thu Nov 17 06:00:01 EST 2016
#  Creating local iRODS rodsuser [thenewaduser]
#  Fri Nov 18 06:00:01 EST 2016
#  Sat Nov 19 06:00:01 EST 2016
#
####################################################################

THE_HOST_URI="ldap://ad.renci.org"
THE_BIND_DN="ad\something"
THE_PASSWORD="xxxxxxxxxxx"
THE_BASE_DN="OU=RENCI Users,DC=ad,DC=renci,DC=org"

echo `date`
for i in `ldapsearch -LLL -x -E pr=1000/noprompt -H ${THE_HOST_URI} -D ${THE_BIND_DN} -w ${THE_PASSWORD} -b ${THE_BASE_DN} uid 2> /dev/null | grep uid | awk '{print $2}'`; do
  error=`iadmin lu ${i}`
  if [ "$error" = "No rows found" ] ; then
    echo "Creating local iRODS rodsuser [${i}]"
    iadmin mkuser ${i} rodsuser
  fi
done

