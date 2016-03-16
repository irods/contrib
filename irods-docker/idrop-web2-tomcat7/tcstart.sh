#!/bin/bash
#tcstart.sh - starts tomcat7
export CATALINA_BASE=/var/lib/tomcat7
export CATALINA_HOME=/usr/share/tomcat7
export JRE_HOME=/usr/lib/jvm/java-7-openjdk-amd64
. $CATALINA_HOME/bin/catalina.sh run
