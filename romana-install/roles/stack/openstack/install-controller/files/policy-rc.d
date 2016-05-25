#!/bin/bash

blocked_services=(
	mysql
	rabbitmq-server
	memcached
	keystone
	glance-api
	glance-registry
	nova-api
	nova-cert
	nova-consoleauth
	nova-scheduler
	nova-conductor
	nova-novncproxy
	nova-compute
	neutron-server
	neutron-dhcp-agent
	neutron-metadata-agent
)

# Ignore options (eg: --quiet)
case "$1" in
--*)
	shift
	;;
esac

case "$2" in
	start)
		for s in "${blocked_services[@]}"; do
			if [[ "$1" = "$s" ]]; then
				exit 101
			fi
		done
		;;
esac

exit 104
