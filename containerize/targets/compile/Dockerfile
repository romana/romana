FROM golang:1.6
MAINTAINER Caleb Gilmour <cgilmour@romana.io>
VOLUME /go/bin /go/src/github.com/romana/core
COPY romana-compile /var/tmp/romana-compile
ENTRYPOINT ["/var/tmp/romana-compile"]
CMD []
