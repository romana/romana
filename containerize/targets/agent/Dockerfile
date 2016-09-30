FROM ubuntu:16.04
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y iptables iproute2 supervisor jq curl python-simplejson
COPY run-romana-agent romana agent agent.py agent_proxy_add_policy.sh agent_proxy_delete_policy.sh agent_dhcp_release.sh /usr/local/bin/
RUN mkdir -p /var/lib/romana/cni-installation /var/lib/romana/templates
COPY cni-romana 10-romana.conf /var/lib/romana/cni-installation/
COPY dot-romana.template romana-agent.template /var/lib/romana/templates/

ENTRYPOINT ["/usr/local/bin/run-romana-agent"]
