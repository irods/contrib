#!/bin/bash
oldFQDN=`sudo cat /var/tmp/FQDN` 
FQDN=`ec2metadata --public-hostname`
 
if [ "$FQDN" != "$oldFQDN" ]
then
  #sudo sed -i 's/location.hostname=.*;/location.hostname=\"'$FQDN'\";/g' /var/www/html/irods-cloud-frontend/app/components/globals.js
  #sed -i 's/serverURL.*/serverURL = \"http:\/\/'"$FQDN"'\" \}/g' /etc/idrop-web/idrop-web-config2.groovy
  #sudo service tomcat7 restart
  echo $FQDN > /var/tmp/FQDN

  # update hostname
  sudo hostname $FQDN 
  sudo su -c "echo $FQDN > /etc/hostname"

  # Update the irods user's environment
  sudo -u irods bash -c 'sed  -i "s|\(.*irods_host.*\)'$oldFQDN'\(.*\)|\1'$FQDN'\2|g" ~irods/.irods/irods_environment.json'

  # Update the tempZone
  sudo su - irods -c "iadmin modresc demoResc host $FQDN"
fi
