FROM ubuntu:14.04
MAINTAINER danb@renci.org

RUN apt-get update ; apt-get upgrade -y

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

#install iRODS
# install package dependencies to prevent Docker build from erring out
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget libcurl4-gnutls-dev && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" >> /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-client-9.4 && \
    wget ftp://ftp.renci.org/pub/irods/releases/4.1.3/ubuntu14/irods-database-plugin-postgres-1.5-ubuntu14-x86_64.deb -O /tmp/irods-dbplugin.deb && \
    wget ftp://ftp.renci.org/pub/irods/releases/4.1.3/ubuntu14/irods-icat-4.1.3-ubuntu14-x86_64.deb -O /tmp/irods-icat.deb &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -y `dpkg -I /tmp/irods-icat.deb | sed -n 's/^ Depends: //p' | sed 's/,//g'` && \
    dpkg -i /tmp/irods-icat.deb && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y `dpkg -I /tmp/irods-dbplugin.deb | sed -n 's/^ Depends: //p' | sed 's/,//g'` && \
    dpkg -i /tmp/irods-dbplugin.deb && \
    apt-get remove --auto-remove  -y --force-yes wget libcurl4-gnutls-dev && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/apt/sources.list.d/*

RUN mkdir /opt/irods

RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install psmisc rsync -y && apt-get clean
ADD ./genresp.sh /opt/irods/genresp.sh
ADD ./setupdb.sh /opt/irods/setupdb.sh
ADD ./config.sh /opt/irods/config.sh
ADD ./bootstrap.sh /opt/irods/bootstrap.sh
RUN chmod a+x /opt/irods/*.sh
ADD ./.export /

EXPOSE 1247
#EXPOSE 1248
CMD "/opt/irods/bootstrap.sh"
