#!/bin/bash

# 52-config.sh
# Configures iRODS using the response values in /opt/irods-aws/setup_responses
export FQDN=`ec2metadata --public-hostname`
sudo hostname $FQDN 
echo $FQDN > /etc/hostname
sudo su -c "echo $FQDN > /var/tmp/FQDN"
sudo su -c "/var/lib/irods/packaging/setup_irods.sh < /opt/irods-aws/setup_responses"

#sudo sed -i 's|// var HOST = "/irods-cloud-backend/";|location.hostname="'$FQDN'";|g' /var/www/html/irods-cloud-frontend/app/components/globals.js

sudo service apache2 restart
