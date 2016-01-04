#!/bin/bash

# Copyright (c) 2015 Pani Networks
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

if [[ -f $HOME/.profile ]]; then
	source "$HOME/.profile"
fi

if ! mkdir /var/tmp/romana-demo-setup; then
	# This has probably been done already. We can skip it
	exit
fi

# Suppress output
exec > /dev/null

# This script currently directly uses the REST API of the Romana Topology and Tenant services
# to configure the hosts/tenants/segments used in a simple setup.

# Create hosts
# TODO: Generate this from variables
curl -X POST -H "Content-Type: application/json" --data '{"name": "ip-192-168-0-10", "ip": "192.168.0.10", "romana_ip": "10.0.0.0/16", "agent_port": 9604 }' http://{{ devstack_controller }}:9603/hosts
curl -X POST -H "Content-Type: application/json" --data '{"name": "ip-192-168-0-11", "ip": "192.168.0.11", "romana_ip": "10.1.0.0/16", "agent_port": 9604 }' http://{{ devstack_controller }}:9603/hosts
curl -X POST -H "Content-Type: application/json" --data '{"name": "ip-192-168-0-12", "ip": "192.168.0.12", "romana_ip": "10.2.0.0/16", "agent_port": 9604 }' http://{{ devstack_controller }}:9603/hosts
curl -X POST -H "Content-Type: application/json" --data '{"name": "ip-192-168-0-13", "ip": "192.168.0.13", "romana_ip": "10.3.0.0/16", "agent_port": 9604 }' http://{{ devstack_controller }}:9603/hosts
curl -X POST -H "Content-Type: application/json" --data '{"name": "ip-192-168-0-14", "ip": "192.168.0.14", "romana_ip": "10.4.0.0/16", "agent_port": 9604 }' http://{{ devstack_controller }}:9603/hosts

# Create tenants and segments
# TODO: Remove the id:0 bits once master branch has fixed its JSON handling
#  -- admin
curl -X POST -H 'Content-Type: application/json' --data "$(printf '{"id": 0, "name": "%s"}' $(openstack project show -f value -c id admin))" http://{{ devstack_controller }}:9602/tenants
curl -X POST -H "Content-Type: application/json" --data '{"id": 0, "name": "default"}' http://{{ devstack_controller }}:9602/tenants/1/segments
curl -X POST -H "Content-Type: application/json" --data '{"id": 0, "name": "s1"}' http://{{ devstack_controller }}:9602/tenants/1/segments
curl -X POST -H "Content-Type: application/json" --data '{"id": 0, "name": "s2"}' http://{{ devstack_controller }}:9602/tenants/1/segments
#  -- demo
curl -X POST -H "Content-Type: application/json" --data "$(printf '{"id": 0, "name": "%s"}' $(openstack project show -f value -c id demo))" http://{{ devstack_controller }}:9602/tenants
curl -X POST -H "Content-Type: application/json" --data '{"id": 0, "name": "default"}' http://{{ devstack_controller }}:9602/tenants/2/segments
curl -X POST -H "Content-Type: application/json" --data '{"id": 0, "name": "s1"}' http://{{ devstack_controller }}:9602/tenants/2/segments
curl -X POST -H "Content-Type: application/json" --data '{"id": 0, "name": "s2"}' http://{{ devstack_controller }}:9602/tenants/2/segments

# Create romana network and subnet
if ! neutron net-show romana 2>/dev/null; then
	neutron net-create --shared --provider:network_type local romana
fi
if ! neutron subnet-show romana-sub 2>/dev/null; then
	neutron subnet-create --ip-version 4 --name romana-sub romana 10.0.0.0/8
fi

# Create keypair
if ! nova keypair-show shared-key 2>/dev/null; then
	nova keypair-add --pub-key ~/.ssh/id_rsa.pub shared-key
fi

# Boot inst1 using romana's network
# - nova boot --flavor m1.micro --image cirros-0.3.4-x86_64-uec --key-name shared-key --nic net-id=$(neutron net-show romana -Fid -f value) inst1

