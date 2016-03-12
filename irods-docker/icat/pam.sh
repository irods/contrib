#!/usr/bin/env bash

# PAM setup
if [ ! -s /etc/irods/chain.pem ] && [ ! -s /etc/irods/server.key ] && [ ! -s /etc/irods/dhparams.pem ]; then
    openssl genrsa -out server.key
    openssl req -new -x509 -key server.key -out chain.pem -days 3650 -config /etc/irods/cert.cfg
    openssl dhparam -2 -out dhparams.pem 2048
    chown 999:999 *.pem
    mv *.pem server.key /etc/irods
    sed -e's/"zone_auth_scheme": "native"/"zone_auth_scheme": "PAM"/' -i /etc/irods/server_config.json
    sed -e's/"zone_auth_scheme": "native"/"zone_auth_scheme": "PAM"/' -i /var/lib/irods/packaging/server_config.json.template
    sed 's@\("icat_host"\)@"irods_ssl_certificate_chain_file": "/etc/irods/chain.pem",\n    "irods_ssl_certificate_key_file": "/etc/irods/server.key",\n    "irods_ssl_dh_params_file": "/etc/irods/dhparams.pem",\n    \1@' -i /etc/irods/server_config.json
    sed -e 's/native/PAM/' -i /var/lib/irods/iRODS/scripts/perl/irods_setup.pl
fi
