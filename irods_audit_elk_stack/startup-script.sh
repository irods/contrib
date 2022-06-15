#!/bin/bash

es_java_heap_size="512m"

usage() {
cat << EOF
Options:
  -m, --es-java-heap-size=<size>    Elasticsearch Java heap size (default: '${es_java_heap_size}')
                                    '<value>[g|G|m|M|k|K]': Run Elasticsearch with the given heap size
                                    'auto':                 Let Elasticsearch/Java decide on a heap size
      --help                        Print usage
EOF
}

die_usage() {
	printf '%s\n' "$1" >&2
	usage
	exit 64
}

while [[ "$#" -gt "0" ]]; do
	case $1 in
		-m|--es-java-heap-size)
			if [ -z "$2" ]; then
				die_usage 'ERROR: "'$1'" requires a non-empty option argument.'
			fi
			es_java_heap_size="$2"
			shift
			;;
		--es-java-heap-size=?*)
			es_java_heap_size="${1#*=}" # Delete everything up to "="
			;;
		--es-java-heap-size=)
			die_usage 'ERROR: "--es-java-heap-size" requires a non-empty option argument.'
			;;
		--help)
			usage
			exit 0
			;;
		*)
			printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
			;;
	esac
	shift
done

es_java_heap_size_option_file="/etc/elasticsearch/jvm.options.d/heap_size.options"

# Set Elasticsearch Java heap size
if [[ "$es_java_heap_size" == "auto" ]]; then
	# Let Elasticsearch/Java handle it
	rm -f "${es_java_heap_size_option_file}"
else
	echo "-Xms${es_java_heap_size}" > "${es_java_heap_size_option_file}"
	echo "-Xmx${es_java_heap_size}" >> "${es_java_heap_size_option_file}"
	chown root:elasticsearch /etc/elasticsearch/jvm.options.d/heap_size.options
fi

# Start services
/etc/init.d/rabbitmq-server start
/etc/init.d/elasticsearch start
/etc/init.d/not-logstash start
/etc/init.d/kibana start

# Print IP addresses
ip addr

# keep alive
tail -f /dev/null
