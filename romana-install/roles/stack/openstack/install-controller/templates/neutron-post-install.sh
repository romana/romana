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

# Suppress output
exec > /dev/null

# Set environment variables
export OS_TOKEN="{{ openstack_service_token }}"
export OS_URL="http://{{ romana_master_ip }}:35357/v3"
export OS_IDENTITY_API_VERSION=3

# Neutron user
if ! openstack user show neutron 2>/dev/null; then
	openstack user create --domain default --password "{{ stack_password }}" neutron
fi
if ! [[ $(openstack role assignment list --project service --user neutron --role admin -f value -c Role) ]]; then
	openstack role add --project service --user neutron admin
fi
# Neutron service
if ! openstack service show neutron 2>/dev/null; then
	openstack service create --name neutron --description "OpenStack Networking" network
fi
service_id=$(openstack service show -f value -c id neutron)

# Neutron endpoints
if ! [[ $(openstack endpoint list --service "$service_id" --interface public -f value -c ID 2>/dev/null) ]]; then
	openstack endpoint create --region RegionOne network public "http://{{ romana_master_ip }}:9696"
fi
if ! [[ $(openstack endpoint list --service "$service_id" --interface internal -f value -c ID 2>/dev/null) ]]; then
	openstack endpoint create --region RegionOne network internal "http://{{ romana_master_ip }}:9696"
fi
if ! [[ $(openstack endpoint list --service "$service_id" --interface admin -f value -c ID 2>/dev/null) ]]; then
	openstack endpoint create --region RegionOne network admin "http://{{ romana_master_ip }}:9696"
fi
