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
elif [[ -f $HOME/.bash_profile ]]; then
       source "$HOME/.bash_profile"
fi

# Suppress output
exec > /dev/null

# Install operator policies
shopt -s nullglob
for i in {{ romana_etc_dir }}/policy.d/*; do
	romana policy add "$i"
done
