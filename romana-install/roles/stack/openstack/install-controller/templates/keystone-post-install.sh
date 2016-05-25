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

# Keystone service
if ! openstack service show keystone 2>/dev/null; then
	openstack service create --name keystone --description "OpenStack Identity" identity
fi
service_id=$(openstack service show -f value -c id keystone)

# Identity endpoints
if ! [[ $(openstack endpoint list --service "$service_id" --interface public -f value -c ID 2>/dev/null) ]]; then
	openstack endpoint create --region RegionOne identity public "http://{{ romana_master_ip }}:5000/v2.0"
fi
if ! [[ $(openstack endpoint list --service "$service_id" --interface internal -f value -c ID 2>/dev/null) ]]; then
	openstack endpoint create --region RegionOne identity internal "http://{{ romana_master_ip }}:5000/v2.0"
fi
if ! [[ $(openstack endpoint list --service "$service_id" --interface admin -f value -c ID 2>/dev/null) ]]; then
	openstack endpoint create --region RegionOne identity admin "http://{{ romana_master_ip }}:35357/v2.0"
fi

# Admin project / user / role
if ! openstack project show admin 2>/dev/null; then
	openstack project create --domain default --description "Admin Project" admin
fi
if ! openstack user show admin 2>/dev/null; then
	openstack user create --domain default --password "{{ stack_password }}" admin
fi
if ! openstack role show admin 2>/dev/null; then
	openstack role create admin
fi
if ! [[ $(openstack role assignment list --project admin --user admin --role admin -f value -c Role) ]]; then
	openstack role add --project admin --user admin admin
fi

# Service project
if ! openstack project show service 2>/dev/null; then
	openstack project create --domain default --description "Service Project" service
fi

# Demo project / user / role
if ! openstack project show demo 2>/dev/null; then
	openstack project create --domain default --description "Demo Project" demo
fi
if ! openstack user show demo 2>/dev/null; then
	openstack user create --domain default --password "{{ stack_password }}" demo
fi

if ! openstack role show user 2>/dev/null; then
	openstack role create user
	openstack role add --project demo --user demo user
fi
