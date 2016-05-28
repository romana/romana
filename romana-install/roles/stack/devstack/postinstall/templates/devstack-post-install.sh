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

if [[ -f $HOME/devstack/openrc ]]; then
	source "$HOME/devstack/openrc" admin admin
fi

# Suppress output
exec > /dev/null

# Create romana network and subnet
if ! neutron net-show romana 2>/dev/null; then
	neutron net-create --shared --provider:network_type local romana
fi
if ! neutron subnet-show romana-sub 2>/dev/null; then
	neutron subnet-create --ip-version 4 --name romana-sub romana {{ romana_cidr }}
fi

# Create keypair
if ! nova keypair-show shared-key 2>/dev/null; then
	nova keypair-add --pub-key ~/.ssh/id_rsa.pub shared-key
fi

# Add Nano and Micro Flavours if it is not present.
if ! nova flavor-show m1.nano &>/dev/null; then
    nova flavor-create m1.nano 42 64 0 1
fi
if ! nova flavor-show m1.micro &>/dev/null; then
    nova flavor-create m1.micro 84 128 0 1
fi
