# TODO: use a more light-weight base image and packaging tool
FROM ubuntu:16.04
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates
COPY romana_aws /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/romana_aws"]
