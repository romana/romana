#!/bin/bash

if [[ -f $HOME/.profile ]]; then
	source "$HOME/.profile"
fi

if ! mkdir /var/tmp/romana-master-setup; then
	# This has probably been done already. We can skip it
	exit
fi

# Suppress output
exec > /dev/null

# Create hosts
# TODO: Generate this from variables
curl -X POST -H "Content-Type: application/json" --data '{"name": "ip-192-168-0-10", "ip": "192.168.0.10", "romana_ip": "10.0.0.0/16", "agent_port": 9604 }' http://{{ devstack_controller }}:9603/hosts
curl -X POST -H "Content-Type: application/json" --data '{"name": "ip-192-168-0-11", "ip": "192.168.0.11", "romana_ip": "10.1.0.0/16", "agent_port": 9604 }' http://{{ devstack_controller }}:9603/hosts
curl -X POST -H "Content-Type: application/json" --data '{"name": "ip-192-168-0-12", "ip": "192.168.0.12", "romana_ip": "10.2.0.0/16", "agent_port": 9604 }' http://{{ devstack_controller }}:9603/hosts
curl -X POST -H "Content-Type: application/json" --data '{"name": "ip-192-168-0-13", "ip": "192.168.0.13", "romana_ip": "10.3.0.0/16", "agent_port": 9604 }' http://{{ devstack_controller }}:9603/hosts
curl -X POST -H "Content-Type: application/json" --data '{"name": "ip-192-168-0-14", "ip": "192.168.0.14", "romana_ip": "10.4.0.0/16", "agent_port": 9604 }' http://{{ devstack_controller }}:9603/hosts

# TODO: Remove this when ML2 driver appropriately looks up agent IP:Port
# Workaround for ML2 driver: Add agent hostnames into /etc/hosts
cp /var/tmp/romana-hosts /etc/hosts
