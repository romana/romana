FROM golang:1.8
MAINTAINER Caleb Gilmour <cgilmour@romana.io>
COPY src /go/src/
COPY romana-compile git-ssh /var/tmp/
COPY github_id_rsa /
ENTRYPOINT ["/var/tmp/romana-compile"]
CMD []
