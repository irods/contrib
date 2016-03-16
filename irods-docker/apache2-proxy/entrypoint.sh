#!/usr/bin/env bash

while [ ! -s /export/etc/irods/chain.pem ];
do
    echo -n .
    sleep 2
done;
echo
httpd-foreground