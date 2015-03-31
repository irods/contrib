#!/bin/bash
oldFQDN=`sed -n 's/.*serverURL = "http:\/\/\(.*\)".*/\1/p' /etc/idrop-web/idrop-web-config2.groovy`
FQDN=`ec2metadata --public-hostname`

if [ "$FQDN" != "$oldFQDN" ]
then
  sed -i 's/serverURL.*/serverURL = \"http:\/\/'"$FQDN"'\" \}/g' /etc/idrop-web/idrop-web-config2.groovy
  service tomcat7 restart
  echo $FQDN > /var/tmp/FQDN
fi
