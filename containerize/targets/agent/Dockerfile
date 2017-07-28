# TODO: use a more light-weight base image and packaging tool
FROM ubuntu:16.04
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y iptables iproute2 jq curl
COPY kubectl etcdctl /usr/local/bin/
RUN mkdir -p /var/lib/romana/cni-installation /var/lib/romana/templates
COPY romana_cni 10-romana.conf /var/lib/romana/cni-installation/
COPY dot-romana.template /var/lib/romana/templates/
COPY romana /usr/local/bin/
COPY simple /usr/local/bin/romana_agent
COPY run-romana-agent /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/run-romana-agent"]
