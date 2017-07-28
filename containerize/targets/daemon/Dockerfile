# TODO: use a more light-weight base image and packaging tool
FROM ubuntu:16.04

COPY etcdctl /usr/local/bin/
COPY romanad /usr/local/bin/
COPY run-romana-daemon /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/run-romana-daemon"]
