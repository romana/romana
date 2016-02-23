#!/bin/bash

CID=$(kubectl -s 192.168.0.10:8080 get pod $1 -o json | jq -r '.status.containerStatuses[].containerID')
PID=$(docker top ${CID##docker://} | awk '/^root/ { print $2 }')

if ! [[ $PID ]]; then 
	echo "Container $CID is on a different host, pick container on current host"
else
	echo "Stepping into container $CID namespace"
	nsenter -t $PID -n
fi
