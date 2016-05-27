#!/bin/bash

blocked_services=(
	libvirtd
	nova-compute
	neutron-dhcp-agent
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
