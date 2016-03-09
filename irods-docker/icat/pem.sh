#!/usr/bin/env bash

# PAM setup
openssl genrsa -out server.key
openssl req -new -x509 -key server.key -out chain.pem -days 3650 -config /home/admin/cert.cfg
openssl dhparam -2 -out dhparams.pem 2048
chown irods:irods *.pem
mv *.pem server.key /var/lib/irods/iRODS/server/config
echo "export irodsSSLCertificateChainFile=/var/lib/irods/iRODS/server/config/chain.pem" >>/etc/profile
echo "export irodsSSLCertificateKeyFile=/var/lib/irods/iRODS/server/config/server.key" >>/etc/profile
echo "export irodsSSLDHParamsFile=/var/lib/irods/iRODS/server/config/dhparams.pem" >>/etc/profile
echo "export irodsSSLCACertificateFile=/var/lib/irods/iRODS/server/config/chain.pem" >>/etc/profile
echo "export irodsSSLVerifyServer=cert" >>/etc/profile
echo "export irodsAuthScheme=PAM">>/etc/profile
#
service postgresql start && \
  su -l -c "iRODS/irodsctl start" irods