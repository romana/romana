# TODO: use a more light-weight base image and packaging tool
FROM ubuntu:16.04
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y iptables iproute2 jq curl
COPY romana /opt/cni/bin/

ENTRYPOINT ["/opt/cni/bin/romana"]
