#
# Build Audit Stack for iRODS Monitoring via Audit Plugin
#
# Used in iRODS Training
#
FROM ubuntu:latest
MAINTAINER Justin James "jjames@renci.org"

RUN apt-get update
RUN apt-get remove --purge openjdk-11-jre
RUN apt-get remove --purge openjdk-11-jre-headless
RUN apt-get install -y openjdk-8-jre-headless
RUN update-java-alternatives --set /usr/lib/jvm/java-1.8.0-openjdk-amd64
RUN export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
RUN apt-get install -y gnupg curl
RUN apt-get install -y wget

RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
RUN apt-get -y install apt-transport-https
RUN echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-6.x.list
RUN apt-get update && apt-get -y install elasticsearch
#curl http://localhost:9200
#RUN curl -XPUT 'http://localhost:9200/irods_audit'
RUN apt-get -y install logstash
RUN /usr/share/logstash/bin/logstash-plugin install logstash-input-stomp

RUN printf 'input {\n    # Read the audit_messages queue messages using the stomp protocol.\n    #stomp {\n    #    host        => "localhost"\n    #    destination => "/queue/audit_messages"\n    #    codec       => plain {\n    #                       charset => "ISO-8859-1"\n    #                   }\n    #}\n\n    rabbitmq {\n      host => "localhost"\n      queue => "audit_messages"\n    }\n}\n\nfilter {\n\n    # Remove AMQP header and footer information from message\n    #ruby {\n    #    code => "event.set('message', event.get('message').sub(/.*__BEGIN_JSON__/, ''))\n    #             event.set('message', event.get('message').sub(/__END_JSON__.*/, ''))"\n    #}\n\n    if "_jsonparsefailure" in [tags] {\n        mutate {\n                  gsub => [ "message", "[\\\\]","" ]\n                  gsub => [ "message", ".*__BEGIN_JSON__", ""]\n                  gsub => [ "message", "__END_JSON__", ""]\n\n        } \n        mutate { remove_tag => [ "tags", "_jsonparsefailure" ] }\n        json { source => "message" }\n\n    }\n\n    # Parse the JSON message\n    json {\n        source       => "message"\n        remove_field => ["message"]\n    }\n\n    # Replace @timestamp with the timestamp stored in time_stamp\n    date {\n        match => [ "time_stamp", "UNIX_MS" ]\n    }\n\n    # Convert select fields to integer\n    mutate {\n        convert => { "int" => "integer" }\n        convert => { "int__2" => "integer" }\n        convert => { "int__3" => "integer" }\n        convert => { "file_size" => "integer" }\n    }\n\n}\n\noutput {\n    # Write the output to elastic search under the irods_audit index.\n    elasticsearch {\n        hosts => ["localhost:9200"]\n        index => "irods_audit"\n    }\n    #stdout {\n    #    codec => rubydebug {}\n    #}\n}\n' > /etc/logstash/conf.d/irods_audit.conf

#/usr/share/logstash/bin/logstash&
RUN curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.deb.sh |  bash
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
RUN apt-get update
RUN apt-get -y install erlang
RUN apt-get -y install rabbitmq-server
RUN rabbitmq-plugins enable rabbitmq_amqp1_0
RUN rabbitmq-plugins enable rabbitmq_management

RUN apt-get -y install kibana
RUN echo "server.host: \"0.0.0.0\"" >> /etc/kibana/kibana.yml

RUN echo "transport.host: localhost" >> /etc/elasticsearch/elasticsearch.yml
RUN echo "transport.tcp.port: 9300" >> /etc/elasticsearch/elasticsearch.yml
RUN echo "http.port: 9200" >> /etc/elasticsearch/elasticsearch.yml
RUN echo "network.host: 0.0.0.0" >> /etc/elasticsearch/elasticsearch.yml


RUN printf 'chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie\nservice elasticsearch start\nservice logstash start\nservice rabbitmq-server start\nservice kibana start\ncurl http://localhost:9200\ncurl -XPUT "http://localhost:9200/irods_audit"\nrabbitmqctl add_user test test\nrabbitmqctl set_user_tags test administrator\nrabbitmqctl set_permissions -p / test ".*" ".*" ".*"\n/bin/bash\nsleep 20\ncurl -XPUT http://localhost:9200/irods_audit/_settings -H \'Content-Type: application/json\' -d\'{"index.mapping.total_fields.limit": 2000}\''> /startup_script.sh
RUN chmod +x /startup_script.sh

CMD /startup_script.sh


WORKDIR /home

