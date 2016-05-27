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

if [[ -f "$HOME/openrc/admin" ]]; then
       source "$HOME/openrc/admin"
fi

# Suppress output
exec > /dev/null

# Create hosts
{% for n in groups.stack_nodes %}
romana host add {{ hostvars[n].ansible_hostname }} {{ hostvars[n].lan_ip }} {{ hostvars[n].romana_gw }} 9604
{% endfor %}

# Create tenants and segments
romana tenant create admin
romana segment add admin default
romana segment add admin frontend
romana segment add admin backend
romana tenant create demo
romana segment add demo default
romana segment add demo frontend
romana segment add demo backend
