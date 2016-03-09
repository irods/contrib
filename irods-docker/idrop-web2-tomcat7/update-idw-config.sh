#!/bin/bash

# replaces prefixes in idrop-web-config2.groovy with environment variables that
# should be configured by docker at runtime

OLD_FQDN=`sed -n 's/.*serverURL = "http:\/\/\(.*\)".*/\1/p' /etc/idrop-web/idrop-web-config2.groovy`
HOST_ADDRESS=$DOCKER_HOSTNAME:$DOCKER_PORT80

if [ "$HOST_ADDRESS" != "$OLD_FQDN" ]
then
  sed -i 's/serverURL.*/serverURL = \"http:\/\/'"$HOST_ADDRESS"'\" \}/g' /etc/idrop-web/idrop-web-config2.groovy
fi
