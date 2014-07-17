#!/bin/bash
supervisorctl start sshd

supervisorctl start postgresql
supervisorctl start irodsServer
sudo su -c "iadmin modresc demoResc host $HOSTNAME" irods

supervisorctl start nginx

/home/admin/update_idwconfig.sh /etc/idrop-web/idrop-web-config2.groovy
supervisorctl start tomcat6



