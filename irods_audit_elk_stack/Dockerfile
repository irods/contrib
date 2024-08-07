# syntax=docker/dockerfile:1.7
#
# Build Audit Stack for iRODS Monitoring via Audit Plugin
#
# Used in iRODS Training
#
FROM ubuntu:24.04

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
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        yq \
    && \
    rm -rf /tmp/*

# Install JDK/JRE
COPY java-excludes.dpkg.cfg /etc/dpkg/dpkg.cfg.d/java-excludes
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        openjdk-17-jre-headless \
    && \
    rm -rf /tmp/*
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
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
# The recommended "November Rain" package repos don't yet have rabbitmq packages for noble,
# but they are present on the cloudsmith repo proper and on the old packagecloud repo.
ADD https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey /usr/share/keyrings/rabbitmq-packagecloud.asc
ADD https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key /usr/share/keyrings/rabbitmq-cloudsmith.asc
ADD https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key /usr/share/keyrings/erlang-cloudsmith.asc
RUN gpg --dearmor -o /usr/share/keyrings/rabbitmq-packagecloud.gpg /usr/share/keyrings/rabbitmq-packagecloud.asc && \
    gpg --dearmor -o /usr/share/keyrings/rabbitmq-cloudsmith.gpg /usr/share/keyrings/rabbitmq-cloudsmith.asc && \
    gpg --dearmor -o /usr/share/keyrings/erlang-cloudsmith.gpg /usr/share/keyrings/erlang-cloudsmith.asc && \
    echo "deb [signed-by=/usr/share/keyrings/rabbitmq-packagecloud.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/rabbitmq.list && \
    echo "deb [signed-by=/usr/share/keyrings/rabbitmq-cloudsmith.gpg] https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-server/deb/ubuntu $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee -a /etc/apt/sources.list.d/rabbitmq.list && \
    echo "deb [signed-by=/usr/share/keyrings/erlang-cloudsmith.gpg] https://ppa1.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/erlang.list && \
    echo "deb [signed-by=/usr/share/keyrings/erlang-cloudsmith.gpg] https://ppa2.novemberain.com/rabbitmq/rabbitmq-erlang/deb/ubuntu $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee -a /etc/apt/sources.list.d/erlang.list
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
