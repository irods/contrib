FROM tomcat:7-jre8

MAINTAINER Mike Knowles <mikewknowles+rods@gmail.com>

# setup idrop war
RUN rm -rf $CATALINA_HOME/webapps/ROOT
RUN wget -O $CATALINA_HOME/webapps/ROOT.war http://people.renci.org/~danb/FOR_DEMOS/iDrop-Web-2/idrop-web2.war
ADD ./server.xml /etc/tomcat7/server.xml
RUN mkdir /etc/idrop-web
ADD ./idrop-web-config2.groovy /etc/idrop-web/idrop-web-config2.groovy
#COPY ./tomcat-users.xml conf/

ADD ./keyresp /keyresp
RUN keytool -genkey -alias tomcat -keyalg RSA -keystore /usr/lib/ssl/.keystore < /keyresp


EXPOSE 8009
ADD ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
#CMD ["/docker-entrypoint.sh"]

