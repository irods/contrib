FROM ubuntu:14.04
MAINTAINER matthias.desmet@ugent.be

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

#Set default irods config
ENV UID=rods \
    GID=rods \
    ROLE=1 \
    LOCALDB=true \
    OBDC_DRIVER=1 \
    DB_HOST=127.0.0.1 \
    DB_PORT=5432 \
    DB_NAME=ICAT \
    DB_USR=irods \
    DB_PSWD=rodspswd \
    DB_PSWD_SALT=RandomStringToHash \
    ZONE=tempZone \
    ICAT_HOST= \
    ZONE_PORT=1247 \
    PARALLEL_PORT_START=20000 \
    PARALLEL_PORT_END=20199 \
    CONTROL_PLANE_PORT=1248 \
    VALIDATION_URI=https://schemas.irods.org/configuration \
    IRODS_ADMIN=rods \
    ZONE_KEY=TEMPORARY_zone_key \
    NEGOTIATION_KEY=TEMPORARY_32byte_negotiation_key \
    CONTROL_PLANE_KEY=TEMPORARY__32byte_ctrl_plane_key \
    IRODS_PSWD=rodspswd \
    VAULT_PATH=/export/Vault

#Update and upgrade packages, install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget lsb-release apt-transport-https && \
    apt-get clean

#Add package repository and install
RUN wget -qO - https://packages.irods.org/irods-signing-key.asc | apt-key add - && \
    echo "deb [arch=amd64] https://packages.irods.org/apt/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/renci-irods.list && \
    apt-get update && \
    apt-get install -y irods-server irods-database-plugin-postgres && \
    apt-get clean

#Create requisite folders
RUN umask 002 && mkdir -p /export/Vault

# Add scripts
ADD ./scripts/genresp.sh /opt/irods/genresp.sh
ADD ./scripts/setupdb.sh /opt/irods/setupdb.sh
ADD ./scripts/bootstrap.sh /opt/irods/bootstrap.sh
RUN chmod a+x /opt/irods/*.sh

EXPOSE 1247 1248
ENTRYPOINT [ "/opt/irods/bootstrap.sh" ]
