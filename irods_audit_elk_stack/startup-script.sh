#!/bin/bash

es_java_heap_size="512m"
ls_workarounds=""

usage() {
cat << EOF
Options:
  -m, --es-java-heap-size=<SIZE>
                            Specify Elasticsearch Java heap size
                            (default: '${es_java_heap_size}')
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
      --help        display this help and exit
EOF
}

die_usage() {
	printf '%s\n' "$1" >&2
	usage
	exit 64
}

die_needed_option_arg() {
	die_usage "ERROR: '$1' requires a non-empty option argument."
}

die_bad_option_arg() {
	die_usage "Unknown/invalid option '$2' for argument '$1'"
}

validate_and_set_heap_size_arg() {
	arg_opt="${2,,}" # lowercase
	if [[ "$arg_opt" == "auto" ]] || [[ $arg_opt =~ ^[0-9]+[g|m|k]?$ ]]; then
		es_java_heap_size="$2"
	else
		die_bad_option_arg "$1" "$2"
	fi
}

validate_boolean_arg() {
	arg_opt="${1,,}" # lowercase
	if [[ "$arg_opt" != "true" ]] && [[ "$arg_opt" != "false" ]]; then
		return 1
	fi
	return 0
}

while [[ "$#" -gt "0" ]]; do
	case $1 in
		-m|--es-java-heap-size)
			if [ -v 2 ]; then
				die_needed_option_arg "$1"
			fi
			validate_and_set_heap_size_arg "$1" "$2"
			shift
			;;
		--es-java-heap-size=?*)
			validate_and_set_heap_size_arg "${1#*=}" # Delete everything up to "="
			;;
		--es-java-heap-size=)
			die_needed_option_arg "--es-java-heap-size"
			;;
		-w|--ls-workarounds)
			if [ -v 2 ]; then
				die_needed_option_arg "$1"
			fi
			ls_workarounds="$2"
			shift
			;;
		--ls-workarounds=?*)
			ls_workarounds="${1#*=}" # Delete everything up to "="
			;;
		--ls-workarounds=)
			die_needed_option_arg "--ls-workarounds"
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
ls_default_file="/etc/default/not-logstash"

# Set Elasticsearch Java heap size
if [[ "$es_java_heap_size" == "auto" ]]; then
	# Let Elasticsearch/Java handle it
	rm -f "${es_java_heap_size_option_file}"
else
	echo "-Xms${es_java_heap_size}" > "${es_java_heap_size_option_file}"
	echo "-Xmx${es_java_heap_size}" >> "${es_java_heap_size_option_file}"
	chown root:elasticsearch /etc/elasticsearch/jvm.options.d/heap_size.options
fi

# Set not-logstash workaround toggles
if [[ -n "$LS_WORKAROUNDS" ]]; then
	if [ -f "${ls_default_file}" ]; then
		cp "${ls_default_file}" "${ls_default_file}.bak"
		echo "" >> "${ls_default_file}"
	fi
	echo "LS_WORKAROUNDS=${ls_workarounds}" >> "${ls_default_file}"
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
