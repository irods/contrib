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
wget -O /tmp/irods-icat.deb ftp://ftp.renci.org/pub/irods/releases/${IRODS_FOLDER}/irods-icat-${IRODS_VERSION}-64bit.deb
wget -O /tmp/irods-postgres.deb ftp://ftp.renci.org/pub/irods/releases/${DB_PLUGIN_FOLDER}/irods-database-plugin-postgres-${DB_PLUGIN_VERSION}.deb
sudo dpkg -i /tmp/irods-icat.deb /tmp/irods-postgres.deb
sudo apt-get -f -y install
#configure tomcat
sudo cp ./server.xml /etc/tomcat7
#configure idrop-web
sudo mkdir /etc/idrop-web
sudo cp ./idrop-web-config2.groovy /etc/idrop-web
sudo rm -rf /var/lib/tomcat7/webapps/ROOT
sudo wget -O /var/lib/tomcat7/webapps/ROOT.war http://people.renci.org/~danb/FOR_DEMOS/iDrop-Web-2/idrop-web2.war
sudo service tomcat7 restart
# configure apache
sudo cp ./ajp.apache /etc/apache2/sites-available
sudo a2enmod proxy_ajp
sudo a2dissite default
sudo a2dissite default-ssl
sudo a2ensite ajp.apache
sudo service apache2 restart
# configure MOTD and cron
sudo cp ./motd.tail /etc
sudo cp ./*_cron /etc/cron.d
./deploy_s3_plugin_1_2.sh
