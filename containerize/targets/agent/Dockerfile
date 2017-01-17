# TODO: use a more light-weight base image and packaging tool
FROM ubuntu:16.04
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y iptables iproute2 supervisor jq curl python-simplejson python-netaddr
COPY romana agent /usr/local/bin/
RUN mkdir -p /var/lib/romana/cni-installation /var/lib/romana/templates /var/lib/romana/policies
COPY romana-cni-wrapper 10-romana.conf /var/lib/romana/cni-installation/
COPY dot-romana.template romana-agent.template /var/lib/romana/templates/
COPY permit-all-pod-to-host.json permit-all-host-to-pod.json /var/lib/romana/policies/
COPY run-romana-agent host-route-monitor /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/run-romana-agent"]
