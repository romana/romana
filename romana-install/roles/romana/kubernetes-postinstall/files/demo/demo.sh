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
    rate=25
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
    kubectl get pods -o json | jq '.items[] | { Name: .metadata.name, podIP: .status.podIP, NodeID: .spec.nodeName, Status: .status.phase }'
}
function get_pod_ip() {
    kubectl get pod "$1" -o json | jq -r '.status.podIP'
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

desc "create a pod on 'frontend' segment in 't1' tenant/owner"
run "kubectl create -f pod-frontend.yaml"

desc "create a pod on 'backend' segment in 't1' tenant/owner"
run "kubectl create -f pod-backend.yaml; sleep 5"

desc "Let’s find out where the pods are"
run "get_pods"

desc "we should only see our 'internal' local interface"
run "kubectl exec nginx-frontend -- ip addr"

desc "Let's look at the state in the frontend segment"
run "kubectl exec nginx-frontend -- curl $(get_pod_ip 'nginx-backend') --connect-timeout 5"

desc "Now let's add a policy that permits frontend to connect to the backend"
run "romana add-policy romana-np-frontend-to-backend.json; sleep 5"
desc "Let's look at the state in the frontend segment"
run "kubectl exec nginx-frontend -- curl $(get_pod_ip 'nginx-backend') --connect-timeout 5"

desc "Demo completed (cleaning up)"
run "romana remove-policy pol1; kubectl delete pod nginx-backend; kubectl delete pod nginx-frontend; kubectl delete replicationcontroller nginx-default"
