# syntax=docker/dockerfile:1.2
#
# Build Audit Stack for iRODS Monitoring via Audit Plugin
#
# Used in iRODS Training
#
FROM ubuntu:20.04

SHELL [ "/bin/bash", "-c" ]
ENV DEBIAN_FRONTEND=noninteractive

# Re-enable apt caching for RUN --mount
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Make sure we're starting with an up-to-date image
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get autoremove -y --purge && \
    rm -rf /tmp/*

# Install some standard stuff
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        apt-transport-https \
        gnupg \
        curl \
    && \
    apt-get install --no-install-recommends -y \
        software-properties-common \
        gosu \
    && \
    rm -rf /tmp/*

# Install yq, needed for init scripts
RUN add-apt-repository --no-update -y ppa:rmescandon/yq
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        yq \
    && \
    rm -rf /tmp/*

# Install JDK/JRE
COPY java-excludes.dpkg.cfg /etc/dpkg/dpkg.cfg.d/java-excludes
ADD https://packages.adoptium.net/artifactory/api/gpg/key/public /usr/share/keyrings/adoptium.asc
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    gpg --dearmor -o /usr/share/keyrings/adoptium.gpg /usr/share/keyrings/adoptium.asc && \
    echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    apt-get install -y \
        adoptium-ca-certificates \
    && \
    rm -rf /tmp/*
ARG java_ver=17
ARG java_vendor=temurin
ARG java_dist=jdk
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        ${java_vendor}-${java_ver}-${java_dist} \
    && \
    rm -rf /tmp/*
ENV JAVA_HOME=/usr/lib/jvm/${java_vendor}-${java_ver}-${java_dist}-amd64
RUN update-java-alternatives --set ${JAVA_HOME}
ENV ES_JAVA_HOME=${JAVA_HOME}

# Install Elasticsearch and Kibana
ARG es_ver=8
COPY elasticsearch/exclude-jvm.dpkg.cfg /etc/dpkg/dpkg.cfg.d/elasticsearch-exclude-jvm
COPY kibana/exclude-node-stuff.dpkg.cfg /etc/dpkg/dpkg.cfg.d/kibana-exclude-node-stuff
ADD https://artifacts.elastic.co/GPG-KEY-elasticsearch /usr/share/keyrings/elasticsearch-keyring.asc
RUN gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg /usr/share/keyrings/elasticsearch-keyring.asc && \
    echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/${es_ver}.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-${es_ver}.x.list
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        elasticsearch \
        kibana \
    && \
    rm -rf /tmp/*
RUN echo "ES_JAVA_HOME=\"${ES_JAVA_HOME}\"" >> /etc/default/elasticsearch

# Install RabbitMQ
ADD https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey /usr/share/keyrings/rabbitmq_rabbitmq-server.asc
ADD https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc /usr/share/keyrings/erlang_solutions.asc
RUN add-apt-repository --no-update -y ppa:rabbitmq/rabbitmq-erlang && \
    gpg --dearmor -o /usr/share/keyrings/rabbitmq_rabbitmq-server.gpg /usr/share/keyrings/rabbitmq_rabbitmq-server.asc && \
    gpg --dearmor -o /usr/share/keyrings/erlang_solutions.gpg /usr/share/keyrings/erlang_solutions.asc && \
    echo "deb [signed-by=/usr/share/keyrings/rabbitmq_rabbitmq-server.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/rabbitmq_rabbitmq-server.list && \
    echo "deb [signed-by=/usr/share/keyrings/erlang_solutions.gpg] https://packages.erlang-solutions.com/ubuntu $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) contrib" | tee /etc/apt/sources.list.d/erlang-solutions.list
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        rabbitmq-server \
    && \
    rm -rf /tmp/*

# Install Python modules for Logstash stand-in
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        python3-qpid-proton \
        python3-elasticsearch \
    && \
    rm -rf /tmp/*

# Install some utils
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install -y \
        procps \
        nano \
        less \
        iproute2 \
        file \
    && \
    rm -rf /tmp/*

# Install RabbitMQ plugins and create administrator account
RUN rabbitmq-plugins enable \
        rabbitmq_amqp1_0 \
        rabbitmq_management \
    && \
    echo 'NODENAME=rabbitmq@localhost' > /etc/rabbitmq/rabbitmq-env.conf && \
    /etc/init.d/rabbitmq-server start && \
    rabbitmqctl add_user test test && \
    rabbitmqctl set_user_tags test administrator && \
    rabbitmqctl set_permissions -p / test ".*" ".*" ".*" && \
    /etc/init.d/rabbitmq-server stop

# Elasticsearch init script and config files
COPY --chown=root:elasticsearch elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
COPY --chown=root:elasticsearch elasticsearch/jvm.options.d/oom_heap_dump.options /etc/elasticsearch/jvm.options.d/
COPY --chmod=755 elasticsearch/elasticsearch.init /etc/init.d/elasticsearch
# Since we have disabled security, we must purge our keystore of secure passwords
RUN /usr/share/elasticsearch/bin/elasticsearch-keystore remove \
        xpack.security.http.ssl.keystore.secure_password \
        xpack.security.transport.ssl.keystore.secure_password \
        xpack.security.transport.ssl.truststore.secure_password

# Kibana init script and config files
COPY --chown=root:kibana kibana/kibana.yml /etc/kibana/kibana.yml
COPY --chmod=755 kibana/kibana.init /etc/init.d/kibana

# Initialize Elasticsearch and Kibana
SHELL [ "/bin/bash", "-x", "-c" ]
COPY elasticsearch/irods_audit.index.json /var/lib/irods-elk/irods_audit.index.json
COPY kibana/irods_dashboard.ndjson /var/lib/irods-elk/irods_dashboard.ndjson
RUN ES_JAVA_OPTS="-Xms512m -Xmx512m" /etc/init.d/elasticsearch start && \
    curl -sLSf -XPUT "http://localhost:9200/irods_audit?pretty=true" \
        -H 'Content-Type: application/json' \
        --data @/var/lib/irods-elk/irods_audit.index.json \
    && \
    curl -sLSf -X GET "http://localhost:9200/irods_audit/_settings?pretty=true&human=true" && \
    curl -sLSf -X GET "http://localhost:9200/irods_audit/_mapping?pretty=true&human=true" && \
    /etc/init.d/kibana start && \
    curl -sLSf -X POST "http://localhost:5601/api/saved_objects/_import" \
        -H "kbn-xsrf: true" \
        --form file=@/var/lib/irods-elk/irods_dashboard.ndjson \
    && echo && \
    /etc/init.d/kibana stop && \
    /etc/init.d/elasticsearch stop && \
    find /var/lib/elasticsearch/ -type f -name '*.lock' -delete
SHELL [ "/bin/bash", "-c" ]

# not-logstash script and init script
COPY --chmod=755 not-logstash/not-logstash.py /var/lib/irods-elk/bin/not-logstash
COPY --chmod=755 not-logstash/not-logstash.init /etc/init.d/not-logstash

WORKDIR /var/lib/irods-elk

COPY --chmod=755 startup-script.sh /var/lib/irods-elk/startup-script.sh
ENTRYPOINT ["/var/lib/irods-elk/startup-script.sh"]
