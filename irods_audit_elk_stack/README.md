# iRODS Audit Demonstration ELK Stack Container

This is an ELK-like stack container used for demonstrating the
[audit rule engine plugin](https://github.com/irods/irods_rule_engine_plugin_audit_amqp) for
[iRODS](https://irods.org/)

## CAVEAT EMPTOR

While some effort has been taken to ensure this container lives up to certain standards of quality, it is by no means production-ready. This is by design.

The express purpose of this container is to demonstrate the audit rule engine plugin, not to serve as an example of a properly configured ELK stack for use in production environments.

Case in point: Elasticstack security is explicitly disabled, and the Python script standing in for Logstash was not written with performance or resilience in mind.

## Container Overview

This Ubuntu Focal-based container contains Elasticsearch 8, Kibana 8, RabbitMQ (with AMQP 1.0 plugin and management plugin), and a Python daemon that was specifically written for this demonstration to stand in for an AMQP 1.0-capable Logstash.

RabbitMQ receives AMQP 1.0 messages containing JSON data from the audit plugin. The Python daemon takes the messages from RabbitMQ, does a little type conversion in the JSON, and puts the information in Elasticsearch. Kibana is configured with a sample dashboard that displays extracted metrics from the data in Elasticsearch.

### Building the Container

The Dockerfile from which this container is built uses new syntax and must be built with BuildKit. Recent versions of Docker come with BuildKit bundled in.

To build this container, use [`docker buildx`](https://docs.docker.com/engine/reference/commandline/buildx/). Alternatively, use `docker build` with the environment variable `DOCKER_BUILDKIT` set to `1`.

### Credentials

RabbitMQ is configured with an administrator account with username `test` and password `test`.  
Security is explicitly disabled in Elasticsearch. No credentials are required for Kibana.  

### Entrypoint

Upon running the container, RabbitMQ, ElasticSearch, the Logstash stand-in, and Kibana will start up, in that order.  
Once all services are running, the entrypoint script runs `ip addr`, which allows for easy access to the container's IP address.

#### Arguments

```
  -m, --es-java-heap-size=<SIZE>
                            Specify Elasticsearch Java heap size
                            (default: '512m')
                            '<value>[g|G|m|M|k|K]': Run Elasticsearch with the
                                      given heap size
                            'auto':   Let Elasticsearch/Java decide on a heap
                                      size
  -w, --ls-workarounds=<LIST>
                            Comma-separated list of not-logstash workarounds
                            to enable.
                            (default: typing)
                            'none':   No workarounds
                            tokens:   Workaround for json-wrapper tokens
                            typing:   Workaround for improperly typed json
                            timestamp:  Workaround for timestamp formatting
                                      and typing
```

### Relevant Ports

| Port    | Protocol         | Description                                                                           |
| ------: | :--------------- | :------------------------------------------------------------------------------------ |
|  `5672` | `TCP`/`AMQP 1.0` | RabbitMQ listens on this port for AMQP 1.0 (and AMQP 0-9-1) clients                   |
| `15672` | `TCP`/`HTTP`     | RabbitMQ management plugin listens on this port for web browsers and HTTP API clients |
|  `5601` | `TCP`/`HTTP`     | Kibana listens on this port for web browsers and REST API clients                     |

## Container Details

### JVM

The JDK/JRE used in this container is [Temurin](https://adoptium.net/temurin) 17 with the Hotspot JVM.

The decision not to use Elasticsearch's bundled JDK/JRE was made for two reasons:
- To de-bloat the container image. Having multiple JDK/JRE installations uses a lot of space.
- To ensure everything uses the same JDK/JRE installation.

Temurin was chosen over the distro-provided JDK/JRE for a couple of reasons:
- The Hotspot AdoptOpenJDK flavor of JVM handles memory pressure very well.
- The AdoptOpenJDK flavors of JVM work well in containers.

Instead of using the [Eclipse-provided Focal-based Temurin 17 docker image](https://hub.docker.com/_/eclipse-temurin?tab=tags&page=1&name=17-jre-focal) <sub>[[Dockerfile](https://github.com/adoptium/containers/blob/main/17/jre/ubuntu/focal/Dockerfile.releases.full)]</sub> for our base, we use the JDK[^1] debian package from [Adoptium's apt repository](https://adoptium.net/installation/linux#_deb_installation_on_debian_or_ubuntu), as the JDK/JRE in the Eclipse-provided containers is not set up to work properly with [Ubuntu/Debian's `java-common` system](https://manpages.debian.org/buster/java-common/update-java-alternatives.8.en.html).

`dpkg` is configured to drop includes, manpages, source zips, and samples from this package, so they are not installed in the container.

[^1]: At present, the full JDK is installed (minus the dpkg excludes). We are investigating using `jlink` to construct a JRE that includes only the components we need for the demonstration.

### RabbitMQ

The [`rabbitmq_amqp1_0`](https://github.com/rabbitmq/rabbitmq-server/tree/master/deps/rabbitmq_amqp1_0) and [`rabbitmq_management`](https://github.com/rabbitmq/rabbitmq-server/tree/master/deps/rabbitmq_management) plugins are enabled. The `test` administrator account is created in the Dockerfile.  

### Elasticsearch

Elasticsearch is configured for a single-node cluster. Security is explicitly disabled, as are machine learning APIs. Both the transport and HTTP ports are configured to specific ports instead of a port range (`9200` and `9300`, respectively).

Elasticsearch is initalized with an (empty) index `irods_audit`, with a field limit of `2000`.

Starting with Elasticsearch 8, `init.d` scripts are no longer included in the deb packages, in lieu of systemd unit files. As such, we provide our own `init.d` script based on the [`init.d` script provided by the Elasticsearch 7 packages](https://github.com/elastic/elasticsearch/blob/v7.17.5/distribution/packages/src/deb/init.d/elasticsearch).

The Elasticsearch JVM is configured to not dump its heap on an out-of-memory error.

`dpkg` is configured to drop the bundled JVM from the Elasticsearch package, so it is not installed in the container.

### Kibana

Kibana is initialized with a sample dashboard useful for demonstrating how one might use Kibana to aggregate metrics from audit data.

Starting with Kibana 8, `init.d` scripts are no longer included in the deb packages, in lieu of systemd unit files. As such, we provide our own `init.d` script based on the `init.d` script provided by the Elasticsearch 7 packages.  
Compared to other `init.d` script implementations for Kibana (and the systemd unit), our `init.d` script has the ability to actually perform health-checks on the running Kibana server. This means that the `start` command does not return until Kibana is actually finished starting up, and the `status` command actually tries to verify that Kibana is not degraded.

`dpkg` is configured to drop includes and manpages from Kibana's bundled `nodejs`, so they are not installed in the container.

### Logstash Stand-In Python Script

We have written a Python script that uses [Qpid Proton](http://web.archive.org/web/20130717085741/http://qpid.apache.org/releases/qpid-0.22/messaging-api/python/api/index.html) to pull AMQP 1.0 messages from RabbitMQ, perform a few transformations on the message (see the following subsection and the script itself for more info on this), and then push the data to Elasticsearch.

The `init.d` script that daemonizes this script is based on the `init.d` script provided by the Elasticsearch 7 packages.

#### Why not Logstash?

Previously, we used Logstash to move data from RabbitMQ to Elasticsearch. This worked well enough for demonstration purposes before 4.3.0 was released, but the fact that it worked *at all* was pure coincidence.  

The iRODS audit rule engine plugin uses [Qpid Proton](https://qpid.apache.org/releases/qpid-proton-0.36.0/proton/cpp/api/index.html) to send [AMQP 1.0](https://www.amqp.org/specification/1.0/amqp-org-download) messages to RabbitMQ, and these messages *remain* in AMQP 1.0 format in the message queue. Logstash would connect to RabbitMQ as an [AMQP 0-9-1](https://www.amqp.org/specification/0-9-1/amqp-org-download) client using the [RabbitMQ input plugin](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-rabbitmq.html) and retrieve these messages. [RabbitMQ is able to convert *some* AMQP 1.0 messages into AMQP 0-9-1](https://github.com/rabbitmq/rabbitmq-server/tree/v3.10.6/deps/rabbitmq_amqp1_0#interoperability-with-amqp-0-9-1) for AMQP 0-9-1 clients, but most are just tagged with `amqp-1.0` in the `type` field of `basic.properties` and passed through otherwise unchanged. As such, the AMQP 1.0 headers are still present in the message as retrieved by Logstash. Since Logstash does not speak AMQP 1.0, this was effectively garbage at the beginning of every message. We previously[^2] had [a workaround](https://github.com/irods/irods_rule_engine_plugin_audit_amqp/commit/3127b3d676d394b2b9bfdad6467d24317a6951c6) for this where we would use a [Logstash Ruby filter](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html) to search for `__BEGIN_JSON__` and `__END_JSON__` tokens in the textual content of the message in order to extract the data. However, this only worked when the AMQP 1.0 header happened to be valid UTF-8 that would not trip up Ruby's regular expression engine. Starting with iRODS 4.3.0, these headers would *always* cause the filter to fail.

[^2]: At time of writing, the audit plugin still inserts the `__BEGIN_JSON__` and `__END_JSON__` tokens.

## Updating This Container

### General Updates

Other than the Ubuntu release itself and the major versions for Temurin, Elasticsearch, and Kibana, the Dockerfile does not specify specific versions of software to be used; therefore, packages can be updated to their latest versions by simply rebuilding the docker image without cache.

### Updating to a new Ubuntu release

Assuming the desired version of Ubuntu introduces no breaking changes and is supported by the third-party apt repositories, the release can be changed in the `FROM` instruction in the Dockerfile.

When updating the Dockerfile, please only use LTS Ubuntu releases, as non-LTS releases are unlikely to have support from third-party apt repositories.

### Updating Java to a new major release

The flavor and major version of Java can be specified at image build-time with the `java_ver`, `java_vendor`, and `java_dist` arguments. (See the Dockerfile for more info.)

When updating the Dockerfile, please only use LTS Java versions, as minor ElasticSearch releases will sometimes drop support for older non-LTS Java versions.

### Updating Elasticsearch and Kibana to a new major release

The major version of Elasticsearch and Kibana can be specified at image build-time with the `es_ver` argument. (See the Dockerfile for more info.)

Elasticsearch is picky about the Java versions it will run on, so changing the Elasticsearch version will often necessitate a change to the Java version as well. Consult the [official Elasticsearch support matrix](https://www.elastic.co/support/matrix#matrix_jvm) for more information.

It is very possible for configuration schema, environment variables, command line arguments, and API endpoints to change between major releases of Elasticsearch and Kibana. Consult official documentation <sub>[[Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/rest-apis.html)] [[Kibana](https://www.elastic.co/guide/en/kibana/current/api.html)]</sub>, default configuration files <sub>[[Elasticsearch](https://github.com/elastic/elasticsearch/tree/main/distribution/src/config)] [[Kibana](https://github.com/elastic/kibana/tree/main/config)]</sub>, systemd unit files <sub>[[Elasticsearch](https://github.com/elastic/elasticsearch/blob/main/distribution/packages/src/common/systemd/elasticsearch.service)] [[Kibana](https://github.com/elastic/kibana/blob/main/src/dev/build/tasks/os_packages/service_templates/systemd/usr/lib/systemd/system/kibana.service)]</sub>, and default environment variables <sub>[[Elasticsearch](https://github.com/elastic/elasticsearch/blob/main/distribution/packages/src/common/env/elasticsearch)] [[Kibana](https://github.com/elastic/kibana/blob/main/src/dev/build/tasks/os_packages/service_templates/env/kibana)]</sub> when updating to a new major release of Elasticsearch and Kibana.

The Kibana [API endpoint](https://www.elastic.co/guide/en/kibana/8.3/saved-objects-api-import.html) used to import the sample dashboard `ndjson` file is, at the time of writing, marked as a technical preview, which means it is likely to change in a future release.

The `ndjson` file containing the sample iRODS Kibana dashboard is not backwards compatible with older versions of Kibana.

#### Updating the sample iRODS Kibana dashboard `ndjson` file

In order to update the `ndjson` file for a new version of Kibana, simply re-[export](https://www.elastic.co/guide/en/kibana/current/managing-saved-objects.html#_export) the Sample iRODS Dashboard, `irods_audit` data view/index pattern, and the dashboard's visualizations as saved objects.

`ndjson` files containing Kibana saved objects are typically [forward-compatible to the next major version](https://www.elastic.co/guide/en/kibana/8.3/managing-saved-objects.html#_compatibility_across_versions), so if the desired version of Kibana is two or more major releases ahead of the currently used version, the `ndjson` must be re-exported by each major release between the current and desired major release.
