FROM ubuntu:16.04
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor mysql-client iproute2
COPY run-romana-services /usr/local/bin/
COPY root tenant topology ipam policy listener /usr/local/bin/
COPY romana.conf.template romana-services.template /var/tmp/
RUN mkdir /etc/romana

ENTRYPOINT ["/usr/local/bin/run-romana-services"]
