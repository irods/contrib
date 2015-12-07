#!/bin/bash
FQDN_LOCATION="/var/tmp/FQDN"
OLD_FQDN=""
if [ -e $FQDN_LOCATION ] ; then
    OLD_FQDN=`sudo cat $FQDN_LOCATION`
fi
NEW_FQDN=$(ec2metadata --public-hostname)

# update hostname
sudo hostname $NEW_FQDN
sudo su -c "echo $NEW_FQDN > /etc/hostname"

# don't run on first boot
if [ -e $FQDN_LOCATION ] ; then
    # update the irods service account's user environment
    sudo -u irods bash -c 'sed -i "s|\(.*irods_host.*\)'$OLD_FQDN'\(.*\)|\1'$NEW_FQDN'\2|g" ~irods/.irods/irods_environment.json'
    # update the resource host information
    sudo su - irods -c "iadmin modresc demoResc host $NEW_FQDN"
fi

# write it down
echo $NEW_FQDN > $FQDN_LOCATION
