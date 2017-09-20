FROM debian:stable-slim
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y iproute2 jq curl
COPY etcdctl /usr/local/bin/
COPY romanad /usr/local/bin/
RUN mkdir -p /var/lib/romana/initial-network
COPY kubeadm-network.json /var/lib/romana/initial-network/
COPY aws-*.json /var/lib/romana/initial-network/
COPY run-romana-daemon /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/run-romana-daemon"]
