#!/bin/bash

# Copyright (c) 2016 Pani Networks
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
romana add-host ip-192-168-0-10 192.168.0.10 10.0.0.0/16 9604
romana add-host ip-192-168-0-11 192.168.0.11 10.1.0.0/16 9604
romana add-host ip-192-168-0-12 192.168.0.12 10.2.0.0/16 9604
romana add-host ip-192-168-0-13 192.168.0.13 10.3.0.0/16 9604
romana add-host ip-192-168-0-14 192.168.0.14 10.4.0.0/16 9604

# Create tenants and segments
# TODO: Remove the id:0 bits once master branch has fixed its JSON handling
#  -- admin
romana create-tenant admin
romana add-segment admin default
romana add-segment admin s1
romana add-segment admin s2
romana create-tenant demo
romana add-segment demo default
romana add-segment demo s1
romana add-segment demo s2

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

# Add Nano and Micro Flavours if it is not present.
available_flavors=$(nova flavor-list)
if [[ ! ( $available_flavors =~ 'm1.nano' ) ]]; then
    nova flavor-create m1.nano 42 64 0 1
fi
if [[ ! ( $available_flavors =~ 'm1.micro' ) ]]; then
    nova flavor-create m1.micro 84 128 0 1
fi
