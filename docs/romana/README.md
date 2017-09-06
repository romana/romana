# Romana core concepts

This document explains some of Romana's core concepts. Oftentimes, a detailed
understanding of those is not required, since Romana strives to provide
sensible defaults and working out-of-the-box configurations. But for custom
deployments or advanced configuration, having an understanding of those
concepts is helpful.


## Terminology

The following terminology is used throughout this document:

* _agent_: This is a Romana component, which runs on every node in a cluster.
  The 'romana agent' is used to configure interfaces, routing or network
  policies on that host.
* _endpoint_: Romana deals with the provisioning of networking for workloads
  in clusters (VMs for OpenStack, pods for Kubernetes). Due to a
  network-centric view, for Romana the most important aspect of a workload is
  the 'network endpoint', which is the IP address and network interface of the
  workload.
* _IPAM_: 'IP Address Manager'. A service that manages IP addresses in a
  network. If anyone in the network needs a new address, a request can be sent
  to IPAM to get 'the next' available IP address from some pre configured
  range. Our specialized IPAM is an extremely important component for Romana,
  since carefully chosen addresses and network prefixes are used to greatly
  collapse routes and reduce the impact on hosts and networking equipment.
* _master node_: One of the nodes of an OpenStack or Kubernetes cluster, which
  fulfills 'master' or 'controller' functions. This is typically where central
  components of the cluster infrastructure are run. Workloads (VMs or pods) may
  or may not be run on master nodes.
* _node_: A host that is a member of a cluster (either OpenStack or
  Kubernetes).
* _policy_: Romana provides network policies to manage network traffic and
  allow or deny access. You can always use the Romana CLI and API to define
  policies. For Kubernetes clusters, Romana also implements a direct and
  automatic mapping of Kubernetes policies to Romana policies.
* _route aggregation_: Since all endpoint IP addresses are fully routable,
  Romana needs to configure and manage the routes within the network. Great
  emphasis has been placed on collapsing those routes (aggregation), so that
  in the end only very few routes actually need to be configured in the network
  infrastructure.
* _workload_: In OpenStack clusters this is typically a VM, while in Kubernetes
  clusters this is normally a pod.

## Networking

* [Fully routed networking](#fully-routed-networks-no-overlay)
* [Address blocks](#romana-address-blocks)
* [Route management](#route-management)

### Fully routed networks, no overlays

Romana does not use network overlays or tunnels. Instead, _endpoints_ (VMs for
OpenStack, pods for Kubernetes) get real, routable IP addresses, which are
configured on cluster hosts. To ensure connectivity between endpoints, Romana
manages routes on cluster hosts as well as network equipment or in the cloud
infrastructure, as needed.

Using real, routable IP addresses has multiple advantages:

* Performance: Traffic is forwarded and processed by hosts and network
  equipment at full speed, no cycles are spent on encapsulating packets.
* Scalability: Native, routed IP networking offers tremendous scalability, as
  demonstrated by the Internet itself. Romana's use of routed IP addressing for
  endpoints means that no time, CPU or memory intensive tunnels or other
  encapsulation needs to be managed or maintained.
* Visibility: Packet traces show the real IP addresses, allowing for easier
  trouble shooting and traffic management.

### Romana address blocks

To increase scalability and reduce resource requirements, Romana allocates
endpoint addresses not individually, but in blocks of addresses. Each block can
be expressed in the form of a CIDR. For example, a typical address block may
have 4 bits (a /28 CIDR), and therefore could contain up to 16 different IP
addresses. [Routing is managed](#route-management) based on those blocks.

Let's look at an example to illustrate:

Assume Romana has been configured to use addresses out of the 10.1.0.0/16
address range and to use /28 blocks. Now assume a first workload needs to be
started. The cluster scheduler decided to place this workload on host A of the
cluster.

Romana's IPAM realizes that no block is in use yet on host A, allocates a block
and 'assigns' it to host A. For example, it may choose to use block
10.1.9.16/28. As this assignment is made, the Romana agent on the cluster
hosts [may create routes](#route-management) to this block's address range, which point at host A.
The address 10.1.9.17 (contained in that address block) could be chosen by IPAM
and is returned as the result of the original address request. Therefore, the
first endpoint gets address 10.1.9.17.

Now a second endpoint needs to be brought up. The scheduler chose host B. IPAM
finds that no block is present on host B yet, creates one (maybe 10.1.9.32/28)
and returns an IP address from that block. For example 10.1.9.33.

The two endpoints (10.1.9.17 on host A and 10.1.9.33 on host B) can communicate
with each other, because Romana automatically setup routing for those address
blocks.

If now a third endpoint needs to be brought up, and it is again scheduled to
host A, then IPAM detects that there is an address block already on host A, but
it is not fully used, yet. Therefore, it returns a free address from that
block, for example 10.1.9.18. Importantly, no new block allocation was
necessary in that case, an no additional routes had to be configured.

As a result, the need to update routes on hosts or in the network
infrastructure is greatly reduced. The larger the address blocks, the less
often routes have to be configured or updated.

Choosing the right address block size is a tradeoff between the number of
routes on one hand, as well as potentially wasted IP addresses on the other: If
the block size was chosen too large then some IP addresses may never be used.
For example, imagine a block size of /24. The block may contain up to 256
addresses. If on a particular host you never run that many workloads then some
of those addresses may be wasted.

If a block size is chosen too small then for a cluster with many endpoints
Romana has to create a lot of routes (either on the hosts or the network
equipment). Romana provides many features to reduce the number of routes and
route updates in the network and therefore, we recommend address block sizes of
at least 4 or 5 bits.

An address block, while in use, is tied to a specific host. When workloads are
stopped and the last address within a block is released, the block itself goes
back into Romana IPAM's free pool. When it is used the next time, it may be
allocated to a different host.

### Route management

Depending on the chosen [topology](#topology), Romana creates and manages
routes for [address blocks](#romana-address-blocks) by a number of different
means.

In most cases, the Romana agents on the cluster hosts create routes to address
blocks on other cluster hosts, at least for those hosts that are on the same L2
segment.

In some data center deployments, Romana will also create routes on network
equipment, such as ToRs. Different means to create those routes can be
configured. For example, BGP broadcasts.

Romana uses topological information about the network in which it is deployed
in order to greatly collapse routes and reduce the number of routes that need
to be created and updated. In many cases, with Romana the network
infrastructure reaches a 'steady state' with very small numbers of routes
and few if any route updates required during the life time of a cluster.

This reduces the impact on the network infrastructure and results in stable,
easily understood and comprehensible cluster operations.

## Topology

* [Prefix groups](#prefix-groups)

### Prefix groups

In order to 
