#!/bin/bash

kubectl -s 192.168.0.10:8080 get pods -o json | jq '.items[] | { Name: .metadata.name, podIP: .status.podIP, NodeID: .spec.nodeName, Status: .status.phase }'
