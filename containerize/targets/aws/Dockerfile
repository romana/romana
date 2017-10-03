FROM debian:stable-slim
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates
COPY romana_aws /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/romana_aws"]
