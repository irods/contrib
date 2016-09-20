#!/bin/bash

export HOME=/var/lib/nagios
 
STATE_OK=0
STATE_UNKNOWN=3

if [ $# -lt 1 ]; then
    echo "Use: check_agent_count.sh <resource name>"
    exit $STATE_UNKNOWN
fi 

host_name=$1

agent_count=$(irods-grid --all status | jq ' .hosts[] |  .hostname + " " + "\(.agents[].agent_pid)"' | grep $host_name | wc -l)

echo "OK - open connections = $agent_count"



