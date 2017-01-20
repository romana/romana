#!/bin/bash
# Contributed by Robert Starmer
readonly  reset=$(tput sgr0)
readonly  green=$(tput bold; tput setaf 2)
readonly yellow=$(tput bold; tput setaf 3)
readonly   blue=$(tput bold; tput setaf 6)
function desc() {
    maybe_first_prompt
    echo "$blue# $@$reset"
    prompt
}
function prompt() {
    echo -n "$yellow\$ $reset"
}
started=""
function maybe_first_prompt() {
    if [ -z "$started" ]; then
        prompt
        started=true
    fi
}
function run() {
    maybe_first_prompt
    rate=80
    if [ -n "$DEMO_RUN_FAST" ]; then
      rate=1000
    fi
    echo "$green$1$reset" | pv -qL $rate
    if [ -n "$DEMO_RUN_FAST" ]; then
      sleep 0.5
    fi
    eval "$1"
    r=$?
    read -d '' -t 0.1 -n 10000 # clear stdin
    prompt
    if [ -z "$DEMO_AUTO_RUN" ]; then
      read -s
    fi
    return $r
}
function relative() {
    for arg; do
        echo "$(realpath $(dirname $(which $0)))/$arg" | sed "s|$(realpath $(pwd))|.|"
    done
}
function get_pods() {
    kubectl ${1:+--namespace "$1"} get pods -o json | jq '.items[] | { Name: .metadata.name, podIP: .status.podIP, NodeID: .spec.nodeName, Status: .status.phase }'
}
function get_service_ip() {
    kubectl ${1:+--namespace "$1"} get services -o json | jq -r '.items[0].spec.clusterIP'
}
function get_pod_ip() {
    kubectl ${2:+--namespace "$2"} get pod "$1" -o json | jq -r '.status.podIP'
}
function delete_tenant() {
    TENANT_ID=$(sudo mysql -s --disable-column-names -u root --password={{ stack_password }} tenant --execute='select id from tenants where name="'"$1"'"')
    if [[ $TENANT_ID ]]; then
        sudo mysql -u root --password={{ stack_password }} tenant --execute='delete from tenants where id='$TENANT_ID
        sudo mysql -u root --password={{ stack_password }} tenant --execute='delete from segments where tenant_id='$TENANT_ID
        sudo mysql -u root --password={{ stack_password }} ipam --execute='delete from ip_am_endpoints where tenant_id='$TENANT_ID
    fi
}

SSH_NODE=$(kubectl get nodes | tail -1 | cut -f1 -d' ')
trap "echo" EXIT
cd "${0%/*}" # Change directory to where the script is

##### DEMO  ######

desc "We'll setup a frontend (client) and backend (server). Following Kubernetes'"
desc "established patterns, the backend pods are behind a service."

desc "Get a list of nodes in the environment."
run "kubectl get nodes"
desc "Anybody here? let's see if we have a pod..."
run "get_pods"

desc "Create a new namespace / tenant."
run "kubectl create -f namespace-tenant-a.yaml"

desc "We want our backend pods to receive traffic via a Kubernetes service."
desc "Here is the service definition:"
run "cat backend-service.yaml"

desc "Let's create the service."
run "kubectl create -f backend-service.yaml"

desc "This is the service that was created."
run "kubectl describe services --namespace='tenant-a'"

desc "Create a pod on the 'backend' segment in 'tenant-a' namespace. The pod labels"
desc "match the selectors in the service definition, so the service 'knows' to"
desc "pods to sent traffic. This is the pod definition:"
run "cat pod-backend.yaml"

desc "Let's create the server pod."
run "kubectl create -f pod-backend.yaml"

desc "Create the client pod on the 'frontend' segment in 'tenant-a' namespace."
run "kubectl create -f pod-frontend.yaml; sleep 5"

desc "Let’s find out where the pods are."
run "get_pods; get_pods 'tenant-a'"

desc "We should only see our 'internal' local interface."
run "kubectl --namespace=tenant-a exec nginx-backend -- ip addr"

desc "The pods can 'ping' each other. Here, the frontend pings the backend pod directly."
run "kubectl --namespace=tenant-a exec nginx-frontend -- ping -c 3 -W 1 $(get_pod_ip 'nginx-backend' 'tenant-a')"

desc "Let's have our frontend load data from the backend via the service."
run "kubectl --namespace=tenant-a exec nginx-frontend -- curl $(get_service_ip 'tenant-a') --connect-timeout 5"

desc "This worked, because by default a Kubernetes namespace is non isolated (open for all traffic)."
desc "So let's add isolation by annotating the namespace."
run "kubectl annotate --overwrite namespaces 'tenant-a' 'net.beta.kubernetes.io/networkpolicy={\"ingress\": {\"isolation\": \"DefaultDeny\"}}'"

desc "Now loading data via the service will fail, since the backend pod is in a different segment."
run "kubectl --namespace=tenant-a exec nginx-frontend -- curl $(get_service_ip 'tenant-a') --connect-timeout 5"

desc "The 'ping' now also fails."
run "kubectl --namespace=tenant-a exec nginx-frontend -- ping -c 3 -W 1 $(get_pod_ip 'nginx-backend' 'tenant-a')"

desc "We add a policy that permits the frontend to connect to the backend. This is the policy:"
run "cat romana-np-frontend-to-backend.yml"

desc "Let's apply the policy now. Note that policies are applied to pods, not the service."
run "kubectl create -f romana-np-frontend-to-backend.yml; sleep 5"

desc "Now we can connect from the frontend to the backend again."
run "kubectl --namespace=tenant-a exec nginx-frontend -- curl $(get_service_ip 'tenant-a') --connect-timeout 5"

desc "But as expected, 'ping' still fails, since it was not part of the policy."
run "kubectl --namespace=tenant-a exec nginx-frontend -- ping -c 3 -W 1 $(get_pod_ip 'nginx-backend' 'tenant-a')"

desc "Demo completed (cleaning up)"
run "kubectl delete -f romana-np-frontend-to-backend.yml; kubectl delete -f pod-backend.yaml; kubectl delete -f pod-frontend.yaml; kubectl delete -f backend-service.yaml; kubectl delete -f namespace-tenant-a.yaml; delete_tenant 'tenant-a'"
