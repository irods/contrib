#!/bin/bash

export HOME=/var/lib/nagios

return=0
/usr/bin/iping "$@" 2>&1 || return=$?

if [ $return -gt 3 ]; then
   exit 2
else
   exit $return
fi

