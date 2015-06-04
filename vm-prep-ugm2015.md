## VM Preparation for User Group Meeting 2015

1. Install Ubuntu 14.04:

  * Download `.iso` from http://www.ubuntu.com/download/desktop
  * User is `learner`
  * Password is `learner`
  * Machine is `learner-vb.example.org`
  * Do install updates
  * Do not install 3rd party applications

2. Install Guest Additions:

  * Devices -> Insert Guest Additions CD image...
  * Run installer
  * Eject Guest Additions
  * Reboot Guest to use Guest Additions
  * Devices -> Shared Clipboard -> Bidirectional

3. Prepare the system:

    ```
    MYHOST=learner-vb.example.org
    sudo apt-get update
    sudo apt-get -y upgrade
    sudo apt-get -y autoremove
    sudo hostname $MYHOST
    sudo sh -c "echo $MYHOST > /etc/hostname"
    sudo sh -c "echo 127.0.0.1 $MYHOST localhost > /etc/hosts"
    sudo apt-get -y install git tig g++ libssl-dev libmagick++-dev
    rm -rf Documents examples.desktop Music Pictures Public Templates Videos
    wget ftp://ftp.renci.org/pub/irods/training/training_jpgs.zip
    unzip training_jpgs.zip
    rm training_jpgs.zip
    gsettings set org.gnome.desktop.screensaver idle-activation-enabled 'false'
    gsettings set org.gnome.desktop.lockdown disable-lock-screen 'true'
    echo `date` > VERSION
    rm ~/.bash_history
    history -c
    sudo reboot
    ```

4. Snapshot the VM

5. Export the `.ova` for download by others

  * File -> Export Appliance
