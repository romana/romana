FROM debian:stable-slim
MAINTAINER Caleb Gilmour <cgilmour@romana.io>

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y bird iproute2
COPY run-bird /usr/local/bin

ENTRYPOINT ["/usr/local/bin/run-bird"]
