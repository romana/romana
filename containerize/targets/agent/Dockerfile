# TODO: use a more light-weight base image and packaging tool
FROM ubuntu:16.04
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y iptables iproute2 supervisor jq curl python-simplejson python-netaddr
COPY romana agent kubectl fix-ec2-srcdestcheck /usr/local/bin/
RUN mkdir -p /var/lib/romana/cni-installation /var/lib/romana/templates /var/lib/romana/policies
COPY cni romana-cni-wrapper 10-romana.conf /var/lib/romana/cni-installation/
COPY dot-romana.template romana-agent.template /var/lib/romana/templates/
COPY permit-all-pod-to-host.json permit-all-host-to-pod.json /var/lib/romana/policies/
COPY run-romana-agent /usr/local/bin/
COPY ipv6-tw-sysctl.conf /etc/

ENTRYPOINT ["/usr/local/bin/run-romana-agent"]
