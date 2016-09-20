#!/bin/bash

export HOME=/var/lib/nagios
 
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

if [ $# -lt 3 ]; then
    echo "Use: check_resource_use.sh <resource name> <warning level> <critical level>"
    exit $STATE_UNKNOWN
fi 

max_bytes=0
percent_used=0

warning_level=$2
critical_level=$3

if ! [[ $warning_level =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Warning level provided is not a valid number."
    exit $STATE_UNKNOWN
fi

if ! [[ $critical_level =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Critical level provided is not a valid number."
    exit $STATE_UNKNOWN
fi
 
context=$(iquest "%s" "select RESC_CONTEXT where RESC_NAME = '$1'") 

for i in $(echo $context | tr ";" "\n"); do
    [[ $i =~ "max_bytes=" ]] && max_bytes=$(echo $i | cut -b11-)
done 

used=$(iquest "%s" "select sum(DATA_SIZE) where RESC_NAME = '$1'")
if [ -z $used ]; then
    used=0
fi

if [[ $max_bytes -gt 0 && $used -gt 0 ]]; then
    percent_used=$(echo "scale=2; ($used / $max_bytes) * 100.0" | bc)
fi

if [ $(echo "$percent_used > $critical_level" | bc -l) -eq "1" ]; then
    echo "CRITICAL - Resource use is above critical level.  byte_used=$used; max_bytes=$max_bytes; critical_threshold=${critical_level}%"
    exit $STATE_CRITICAL
fi

if [ $(echo "$percent_used > $warning_level" | bc -l) -eq "1" ]; then
    echo "WARNING - Resource usage is above warning level.  byte_used=$used; max_bytes=$max_bytes; warning_threshold=${warning_level}%"
    exit $STATE_WARNING
fi

echo "OK - Resource use is below warning and critical levels.  bytes_used=$used; max_bytes=$max_bytes"
exit $STATE_OK
