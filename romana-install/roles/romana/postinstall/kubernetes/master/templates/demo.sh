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
    rate=30
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
function get_pod_ip() {
    kubectl ${2:+--namespace "$2"} get pod "$1" -o json | jq -r '.status.podIP'
}

SSH_NODE=$(kubectl get nodes | tail -1 | cut -f1 -d' ')
trap "echo" EXIT
cd "${0%/*}" # Change directory to where the script is
##### DEMO  ######
desc "Get a list of nodes in the environment"
run "kubectl get nodes"
desc "anybody here? let's see if we have a pod"
run "get_pods"

desc "How about we start up a few pods with a resource controller"
run "kubectl create -f example-controller.yaml"
desc "anybody here now?"
run "get_pods"

desc "create the namespace for some additional pods"
run "kubectl create -f namespace-tenant-a.yaml"
desc "create a pod on 'frontend' segment in 'tenant-a' namespace"
run "kubectl create -f pod-frontend.yaml"

desc "create a pod on 'backend' segment in 'tenant-a' namespace"
run "kubectl create -f pod-backend.yaml; sleep 5"

desc "let’s find out where the pods are"
run "get_pods; get_pods 'tenant-a'"

desc "we should only see our 'internal' local interface"
run "kubectl --namespace=tenant-a exec nginx-backend -- ip addr"

desc "let's have our frontend load data from the backend"
run "kubectl --namespace=tenant-a exec nginx-frontend -- curl $(get_pod_ip 'nginx-backend' 'tenant-a') --connect-timeout 5"

desc "we can add isolation too. Let's see that. Quick cleanup first"
run "kubectl --namespace=tenant-a delete pod nginx-backend; kubectl --namespace=tenant-a delete pod nginx-frontend; sleep 5"

desc "enable isolation for 'tenant-a' namespace."
run "kubectl annotate --overwrite namespaces 'tenant-a' 'net.alpha.kubernetes.io/network-isolation=on'"

desc "create the frontend and backend pods"
run "kubectl create -f pod-frontend.yaml; kubectl create -f pod-backend.yaml; sleep 5"

desc "let's try to have the frontend load data from the backend"
run "kubectl --namespace=tenant-a exec nginx-frontend -- curl $(get_pod_ip 'nginx-backend' 'tenant-a') --connect-timeout 5"

desc "now let's add a policy that permits frontend to connect to the backend"
run "curl -X POST -H 'Content-Type: application/yaml' -d @romana-np-frontend-to-backend.json http://{{ romana_master_ip }}:8080/apis/romana.io/demo/v1/namespaces/tenant-a/networkpolicys; sleep 5"

desc "this permits us to connect from frontend to backend"
run "kubectl --namespace=tenant-a exec nginx-frontend -- curl $(get_pod_ip 'nginx-backend' 'tenant-a') --connect-timeout 5"

desc "Demo completed (cleaning up)"
run "curl -X DELETE http://{{ romana_master_ip }}:8080/apis/romana.io/demo/v1/namespaces/tenant-a/networkpolicys/pol1; kubectl --namespace=tenant-a delete pod nginx-backend; kubectl --namespace=tenant-a delete pod nginx-frontend; kubectl delete namespace tenant-a; kubectl delete replicationcontroller nginx-default"
