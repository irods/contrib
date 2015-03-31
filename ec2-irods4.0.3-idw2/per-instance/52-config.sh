#!/bin/bash

# 52-config.sh
# Configures iRODS using the response values in /opt/irods-aws/setup_responses

sudo su -c "/var/lib/irods/packaging/setup_irods.sh < /opt/irods-aws/setup_responses"
