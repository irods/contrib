#!/bin/bash

# build.sh
# Installs iRODS and iDrop Web

IRODS_FOLDER=$1
IRODS_VERSION=$2
DB_PLUGIN_FOLDER=$3
DB_PLUGIN_VERSION=$4


sudo apt-get update
sudo apt-get -y install postgresql openjdk-7-jdk
sudo update-java-alternatives -s java-1.7.0-openjdk-amd64
sudo apt-get -y install tomcat7 apache2
sudo apt-get install unzip
wget -O /tmp/irods-icat.deb ftp://ftp.renci.org/pub/irods/releases/${IRODS_FOLDER}/ubuntu14/irods-icat-${IRODS_VERSION}-ubuntu14-x86_64.deb
wget -O /tmp/irods-postgres.deb ftp://ftp.renci.org/pub/irods/releases/${DB_PLUGIN_FOLDER}/ubuntu14/irods-database-plugin-postgres-${DB_PLUGIN_VERSION}-ubuntu14-x86_64.deb
sudo dpkg -i /tmp/irods-icat.deb /tmp/irods-postgres.deb
sudo apt-get -f -y install
#configure tomcat
sudo cp ./server.xml /etc/tomcat7

#configure idrop-web
#sudo mkdir /etc/idrop-web
#sudo cp ./idrop-web-config2.groovy /etc/idrop-web
set -x

# configure cloud browser
wget -O /tmp/irods-cloud-backend.war https://code.renci.org/gf/download/frsrelease/239/2717/irods-cloud-backend.war
wget -O /tmp/irods-cloud-frontend.zip https://code.renci.org/gf/download/frsrelease/239/2712/irods-cloud-frontend.zip
sudo -u tomcat7 bash -c "cp /tmp/irods-cloud-backend.war /var/lib/tomcat7/webapps"
sudo unzip /tmp/irods-cloud-frontend.zip -d /var/www/
sudo sed -i 's/:8080//g' /var/www/irods-cloud-frontend/app/components/globals.js
sudo cp ./irods-cloud-backend-config.groovy /etc

sudo rm -rf /var/lib/tomcat7/webapps/ROOT
sudo service tomcat7 restart

# configure apache
sudo cp ./ajp.conf /etc/apache2/sites-available
sudo a2enmod proxy_ajp
sudo a2dissite 000-default
sudo a2dissite default-ssl
sudo a2ensite ajp
sudo service apache2 restart
# configure MOTD and cron
sudo cp ./motd.tail /etc
sudo cp ./*_cron /etc/cron.d
./deploy_s3_plugin_1_2.sh

set +x
