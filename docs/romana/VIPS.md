# Romana VIPs

Kubernetes users running on premises that want an easy way to expose their
services outside a cluster on their datacenter network can use
[external-IPs](https://kubernetes.io/docs/concepts/services-networking/service/#external-ips).

Although external-IPs are simple, they represent a single point of failure for
the service and require manual allocation and configuration on the nodes. When
there are many to configure, this can be tedious and prone to error. Romana
VIPs are a solution to these problems.

Romana VIPs are defined by an annotation in a [service
spec](https://raw.githubusercontent.com/wiki/romana/romana/files/nginx.yml).
Romana then automatically brings up that IP on a node. Romana chooses a node
with a pod running locally to avoid network latency within the cluster. When a
node with a Romana VIP fails, Romana will bring up the VIP on a new node,
providing failover for external services.

Romana VIPs are useful for exposing services on datacenter LANs that only need
simple kubeproxy load balancing across pods. Romana VIPs can also be used to
expose individual pods when a stable IP is required, such as Cassandra and
other Big Data applications. Romana VIPs work in conjunction with [Romana
DNS](https://github.com/romana/romanadns), which can be deployed as a service
discovery mechanism for individual pods exposed outside of a cluster.

Romana VIP failover requires that all nodes be on the same network segment.
Addresses for Romana VIPs must be manually provisioned on the network.

## Example configuration and yaml file

The example below shows a RomanaIP (192.168.99.101) configured on a node for
the nginx service by adding the `romanaip` annotation to the spec.

    ...
    kind: Service
    metadata:
      name: nginx
      annotations:
        romanaip: '{"auto": false, "ip": "192.168.99.101"}'
    ...


The complete service spec is available [here](https://raw.githubusercontent.com/wiki/romana/romana/files/nginx.yml)

***
