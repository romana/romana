FROM debian:stable-slim
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y jq curl
COPY etcdctl /usr/local/bin/
COPY romana_route_publisher /usr/local/bin/
COPY run-route-publisher /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/run-route-publisher"]
