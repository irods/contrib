FROM tomcat:7-jre7

MAINTAINER Mike Knowles <mikewknowles+rods@gmail.com>

# setup idrop war
ADD ./server.xml /etc/tomcat7/server.xml
RUN mkdir /etc/idrop-web
ADD ./idrop-web-config2.groovy /etc/idrop-web/idrop-web-config2.groovy
RUN rm -rf $CATALINA_HOME/webapps/ROOT
RUN wget -O $CATALINA_HOME/webapps/ROOT.war http://people.renci.org/~danb/FOR_DEMOS/iDrop-Web-2/idrop-web2.war

EXPOSE 8009


