irods-aws
=========

Installs a minimal iRODS installation with iDrop Web 2 on an Amazon Machine
Image.

This is meant to be installed on an Ubuntu 12.04 Amazon Machine Image.
To find an appropriate target, see http://cloud-images.ubuntu.com/locator/ec2/

Use the following process to bootstrap the AWS image by copying it into 
user-data. The process:
* installs git,
* clones this repository,
* downloads and installs iRODS and iDrop Web 2, and their dependencies,
* installs a cron job to update the iDrop Web 2 config on hostname changes.

```bash
#!/bin/bash
sudo apt-get -y install git
cd /opt
sudo git clone https://github.com/irods/contrib
mv /opt/contrib/ec2-irods4.0.3-idw2 /opt/irods-aws
cd /opt/irods-aws

# For 4.0.3
#./deploy.sh 4.0.3 4.0.3-64bit 4.0.3-with-v1.4-database-plugins 1.4

# For 4.1.3
./deploy.sh 4.1.3/ubuntu14 4.1.3-ubuntu14-x86_64 4.1.3/ubuntu14 1.5-ubuntu14-x86_64
sudo shred -u /root/.ssh/authorized_keys
sudo shred -u /etc/ssh/*_key /etc/ssh/*_key.pub
sudo shred -u /home/ubuntu/.ssh/authorized_keys
sudo shred -u /home/ubuntu/.*history
sudo shred -u /var/log/lastlog
sudo shred -u /var/log/wtmp
sudo touch /var/log/lastlog
sudo touch /var/log/wtmp
history -c
```

The resultant iRODS installation has a single user with a password that is
generated randomly on creation of the instance. Instructions for setting a
new password are in ./per-once/motd.tail, which is displayed at instance login.
