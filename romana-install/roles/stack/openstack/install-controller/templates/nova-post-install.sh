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

# Nova user
if ! openstack user show nova 2>/dev/null; then
	openstack user create --domain default --password "{{ stack_password }}" nova
fi
if ! [[ $(openstack role assignment list --project service --user nova --role admin -f value -c Role) ]]; then
	openstack role add --project service --user nova admin
fi
# Nova service
if ! openstack service show nova 2>/dev/null; then
	openstack service create --name nova --description "OpenStack Compute" compute
fi
service_id=$(openstack service show -f value -c id nova)

# Nova endpoints
if ! [[ $(openstack endpoint list --service "$service_id" --interface public -f value -c ID 2>/dev/null) ]]; then
	openstack endpoint create --region RegionOne compute public "http://{{ romana_master_ip }}:8774/v2/%(tenant_id)s"
fi
if ! [[ $(openstack endpoint list --service "$service_id" --interface internal -f value -c ID 2>/dev/null) ]]; then
	openstack endpoint create --region RegionOne compute internal "http://{{ romana_master_ip }}:8774/v2/%(tenant_id)s"
fi
if ! [[ $(openstack endpoint list --service "$service_id" --interface admin -f value -c ID 2>/dev/null) ]]; then
	openstack endpoint create --region RegionOne compute admin "http://{{ romana_master_ip }}:8774/v2/%(tenant_id)s"
fi
