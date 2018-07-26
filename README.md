# Romana - network and security automation solution for cloud native applications

Romana is a network and security automation solution for cloud native
applications.

* Romana automates the creation of isolated cloud native networks
  and secures applications with a distributed firewall that applies access
  control policies consistently across all endpoints (pods or VMs) and
  services, wherever they run.
* Through Romana's topology aware IPAM, endpoints receive natively routable
  addresses: No overlays or tunnels are required, increasing performance
  and providing operational simplicity.
* Because IP addresses are assigned with network topology in mind, routes
  within the network are highly aggregated, reducing the impact on networking
  hardware, and allowing more secure configurations.
* Supports Kubernetes and OpenStack clusters, on premise or on AWS.

# Installation

To get started with Romana on Kubernetes, go [here](docs/kubernetes/README.md).

For OpenStack installations, please contact us by email or on Slack.

We are working on more detailed documentation to cover all the features and
installation methods. Reach out to the team via email, Slack or GitHub if you
need some help in the meantime.

# Additional documentation

* [Romana core concepts and terminology](docs/romana/README.md): Find out how
  Romana is different and how it accomplishes simplified routing for endpoints.
* [Romana's topology configuration](docs/romana/TOPOLOGY.md): Explanation and
  examples of how to configure Romana for different networking environments.
* [Romana VIPs](docs/romana/VIPS.md): External IPs for Kubernetes clusters,
  managed by Romana with automatic failover.
* [Romana DNS](docs/romana/DNS.md): How to setup DNS for Romana VIPs.
* [Romana network policies](docs/romana/POLICIES.md): Introduction to Romana
  network policies.
* [Romana route publisher](docs/romana/ROUTE_PUBLISHER.md): In routed L3
  networks, the route publisher announces the necessary routes either via BGP
  or OSPF.

Visit [http://romana.readthedocs.io/](http://romana.readthedocs.io/) for the complete documentation.

# Code

This repository contains the documentation and installation tools for the Romana project.
You can find the application code in the [core](https://github.com/romana/core) repository.

Latest stable release: 2.0

# Contact Us

* By email: [info@romana.io](mailto:info@romana.io)
* On the [Romana Slack](https://romana.slack.com/). Please request an invite
  by email.
* On GitHub, just open an [issue](https://github.com/romana/romana/issues/new)
