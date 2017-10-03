FROM debian:stable-slim
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y jq curl
COPY kubectl etcdctl /usr/local/bin/
COPY romana_listener /usr/local/bin/
COPY run-romana-listener /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/run-romana-listener"]
