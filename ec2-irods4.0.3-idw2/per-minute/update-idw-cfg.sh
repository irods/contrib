#!/bin/bash
oldFQDN=`sed -n 's/.*serverURL = "http:\/\/\(.*\)".*/\1/p' /etc/idrop-web/idrop-web-config2.groovy`
FQDN=`ec2metadata --public-hostname`
 
if [ "$FQDN" != "$oldFQDN" ]
then
  sed -i 's/serverURL.*/serverURL = \"http:\/\/'"$FQDN"'\" \}/g' /etc/idrop-web/idrop-web-config2.groovy
  service tomcat7 restart
  echo $FQDN > /var/tmp/FQDN

  # update hostname
  sudo hostname $FQDN 
  sudo su -c "echo $FQDN > /etc/hostname"

  # Update the irods user's environment
  sed  -i "s|\(.*irods_host.*\)$oldFQDN\(.*\)|\1$FQDN\2|g" ~irods/.irods/irods_environment.json

  # Update the tempZone
  sudo su - irods -c "iadmin modresc demoResc host $FQDN"
fi
