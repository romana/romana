#!/bin/bash
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

SSH_NODE=$(kubectl get nodes | tail -1 | cut -f1 -d' ')
trap "echo" EXIT
cd "${0%/*}" # Change directory to where the script is

##### Scale Demo  ######

desc "We'll setup a deployment (cirros) and scale it to show route tables."

desc "Lets see the number of nodes present in the cluster."
run "kubectl get nodes -a -o wide"
desc "Anybody here? let's see if we have a pod..."
run "kubectl get pods -a -o wide"

desc "Let's check the routes currently present."
run "ip route show table 10"

desc "Now create the deployment with 8 pods."
run "kubectl run cirros --image=cirros --replicas=8 && sleep 10"

desc "Did the pods show up correctly?"
run "kubectl get pods -a -o wide"

desc "Let's re-check the routes and see if anything changed?."
run "ip route show table 10"

desc "Now lets scale the pods to 16 and see the change in routes."
run "kubectl scale deploy/cirros --replicas=16 && sleep 10"

desc "Did the pods show up correctly?"
run "kubectl get pods -a -o wide"

desc "Let's re-check the routes and see if anything changed?."
run "ip route show table 10"

desc "Now lets scale the pods to 40 and see the change in routes."
run "kubectl scale deploy/cirros --replicas=40 && sleep 15"

desc "Did the pods show up correctly?"
run "kubectl get pods -a -o wide"

desc "Let's re-check the routes and see if anything changed?."
run "ip route show table 10"

desc "Demo done! lets clean up"
run "kubectl delete deploy/cirros"
