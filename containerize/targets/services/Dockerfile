# TODO: use a more light-weight base image and packaging tool
FROM ubuntu:16.04
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor mysql-client iproute2 jq curl ca-certificates
COPY romana root tenant topology ipam policy listener kube-cni-proxy romana-aws kubectl /usr/local/bin/
RUN mkdir -p /var/lib/romana/templates
COPY dot-romana.template romana.conf.template romana-services.template romana-aws.template route-publisher-bird.template /var/lib/romana/templates/
RUN mkdir /etc/romana
COPY run-romana-services auto-create-segment /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/run-romana-services"]
