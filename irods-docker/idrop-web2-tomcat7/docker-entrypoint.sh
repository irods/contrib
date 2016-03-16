#!/usr/bin/env bash

while [ ! -s /export/etc/irods/chain.pem ];
do
    echo -n .
    sleep 2
done;
echo
keytool -import -storepass changeit -noprompt -file /export/etc/irods/chain.pem -keystore /etc/ssl/certs/java/cacerts

catalina.sh run