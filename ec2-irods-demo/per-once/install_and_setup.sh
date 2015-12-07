#!/bin/bash

# build.sh
# Installs iRODS, Cloud Browser, S3 plugin, and WebDAV

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

IRODS_VERSION=$1
DB_PLUGIN_VERSION=$2

# prepare and install prerequisites
sudo apt-get update
sudo apt-get -y install postgresql openjdk-7-jdk
sudo update-java-alternatives -s java-1.7.0-openjdk-amd64
sudo apt-get -y install tomcat7 apache2
sudo apt-get -y install unzip

# install postgres and irods
wget -O /tmp/irods-icat.deb ftp://ftp.renci.org/pub/irods/releases/${IRODS_VERSION}/ubuntu14/irods-icat-${IRODS_VERSION}-ubuntu14-x86_64.deb
wget -O /tmp/irods-postgres.deb ftp://ftp.renci.org/pub/irods/releases/${IRODS_VERSION}/ubuntu14/irods-database-plugin-postgres-${DB_PLUGIN_VERSION}-ubuntu14-x86_64.deb
sudo dpkg -i /tmp/irods-icat.deb /tmp/irods-postgres.deb
sudo apt-get -f -y install

# configure tomcat
sudo cp $SCRIPTPATH/server.xml /etc/tomcat7

# configure cloud browser
CLOUD_BACKEND_DOWNLOAD="https://code.renci.org/gf/download/frsrelease/239/2717/irods-cloud-backend.war"
CLOUD_FRONTEND_DOWNLOAD="https://code.renci.org/gf/download/frsrelease/239/2712/irods-cloud-frontend.zip"
TMPFILE="/tmp/irods-cloud-backend.war"
wget -O $TMPFILE $CLOUD_BACKEND_DOWNLOAD
sudo -u tomcat7 bash -c "cp $TMPFILE /var/lib/tomcat7/webapps"
TMPFILE="/tmp/irods-cloud-frontend.zip"
wget -O $TMPFILE $CLOUD_FRONTEND_DOWNLOAD
sudo unzip $TMPFILE -d /var/www/
#sudo sed -i 's/\(location\.hostname\)/\1+":"+location.port/' /var/www/irods-cloud-frontend/app/components/globals.js
sudo cp $SCRIPTPATH/irods-cloud-backend-config.groovy /etc
sudo echo '<html><meta http-equiv="refresh" content="0;URL=irods-cloud-frontend"></html>' > /var/www/index.html

# configure webdav
WEBDAV_DOWNLOAD="https://code.renci.org/gf/download/frsrelease/241/2732/irods-webdav.war"
TMPFILE="/tmp/irods-webdav.war"
wget -O $TMPFILE $WEBDAV_DOWNLOAD
sudo -u tomcat7 bash -c "cp $TMPFILE /var/lib/tomcat7/webapps/irods-webdav.war"
sudo mkdir -p /etc/irods-ext
sudo cp $SCRIPTPATH/irods-webdav.properties /etc/irods-ext/

# restart tomcat
sudo rm -rf /var/lib/tomcat7/webapps/irods-webdav
sudo service tomcat7 restart

# configure apache
sudo cp $SCRIPTPATH/ajp.conf /etc/apache2/sites-available
sudo sed -i '/Listen 80/a Listen 8080' /etc/apache2/ports.conf
sudo a2enmod headers
sudo a2enmod proxy_ajp
sudo a2dissite 000-default
sudo a2dissite default-ssl
sudo a2ensite ajp
sudo service apache2 restart

# install S3 plugin
TMPFILE="/tmp/s3_plugin.deb"
S3_PLUGIN_DOWNLOAD="ftp://ftp.renci.org/pub/irods/plugins/irods_resource_plugin_s3/1.3/irods-resource-plugin-s3-1.3-ubuntu14-x86_64.deb"
sudo wget -O $TMPFILE $S3_PLUGIN_DOWNLOAD
sudo dpkg -i $TMPFILE

# configure MOTD and cron
sudo cat $SCRIPTPATH/motd.tail >> /etc/motd
