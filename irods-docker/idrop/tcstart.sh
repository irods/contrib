#!/bin/bash
export CATALINA_BASE=/var/lib/tomcat6
export CATALINA_HOME=/usr/share/tomcat6
export JRE_HOME=/usr/lib/jvm/java-6-openjdk-amd64
. $CATALINA_HOME/bin/catalina.sh run

