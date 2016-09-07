#!/bin/bash -e

body=`echo $1 | cut -d'=' -f2`
mac=$(echo $body | jq -r '.mac_address')
ip=$(echo $body | jq -r '.ip_address')
iface=romana-gw

/usr/bin/dhcp_release $iface $ip $mac
