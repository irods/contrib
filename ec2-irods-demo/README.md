ec2-irods-demo
==============

Prepares an Ubuntu 14.04 Amazon Machine Image with:
* a minimal iRODS installation
* iRODS S3 resource plugin
* Cloud Browser
* WebDAV

The image is rebootable (IP changes are accounted for).

The resultant iRODS installation has a single user with a password that is
generated randomly on creation of the instance. Instructions for setting a
new password are in ./per-once/motd.tail, which is displayed at instance login.
