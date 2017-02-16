# Containerize

![containerize all the things](https://cdn.meme.am/instances/500x/65415534.jpg)

# Installation

## Using kubeadm

Please see the [kubeadm getting started guide](http://kubernetes.io/docs/getting-started-guides/kubeadm/) and complete steps 1, 2, and 3.

Once completed, run this command on the master node:

```bash
kubectl apply -f https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-kubeadm.yml
```

## Using kops

For installation on a cluster created with [kops](https://github.com/kubernetes/kops/) using `--networking cni`, Romana can be installed by running:

```bash
kubectl apply -f https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-kops.yml
```

### Limitations

There are some minor restrictions in an automated, single-command install of Romana that differ from the environment kops creates by default.

1. *Single subnet*: An automated setup only supports a single subnet in this release.
Multiple subnets are supported, but automating that configuration is coming in a future release.
2. *Smaller CIDR*: By default, kops will use `172.20.0.0/16` as a network CIDR and allocate smaller /19 subnets from that range.
Please override this with `--network-cidr=172.20.0.0/21`
3. *EC2 Source Dest Check*: By default, AWS EC2 instances have `SourceDestCheck` enabled.
This needs to be disabled for pods on different hosts to communicate using their podIP addresses.

## Manual / Custom Installation

The installation steps above provide preconfigured values for a number of Romana components. These can be customized to suit a specific environment, and can be installed manually.

### romana-services pod

The romana services pod contains the database and microservices used within Romana.
This includes features for IPAM (IP Address Allocation), Policy, and Kubernetes integration.

There are two different ways to deploy this:

1. A manifest file
2. A daemonset restricted to the master node

To install using a manifest, you can refer to [romana-services-manifest.yml](https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-services-manifest.yml).
This file should be copied into the "manifest path" on your master node, usually `/etc/kubernetes/manifest`.

To install using a daemonset, refer to [romana-services-daemonset.yml](https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-services-daemonset.yml).
This is installed using `kubectl apply -f romana-services-daemonset.yml`

#### Mandatory settings

The `--cidr` option must be specified.
This is the CIDR that Romana will use for allocating pod IPs within the cluster.
It should not overlap with the host networking or other routable networks.
Example: `--cidr=10.192.0.0/12`

#### Optional settings

- `--api-server`: URL for HTTP connections to the Kubernetes API Server. Default: http://127.0.0.1:8080
- `--interface`: The interface to use for detecting the host's address. Default: eth0
- `--ip-address`: The IP address for Romana services. Default: address from `--interface.
- `--nodes`: The number of nodes in the cluster. Default: 256
- `--namespaces`: The number of namespaces in the cluster. Default: 16
- `--segments`: The number of segments permitted per namespace: Default: 16
- `--cloud`: Enable cloud integration. No default. Permitted values: none, aws

### romana-root service

The romana-root service contains addresses and configuration of the other microservices used within Romana.
To expose this service within a Kubernetes cluster, a cluster IP address is allocated and associated with the `romana-services` application.

To install the service, refer to [romana-root-service.yml](https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-root-service.yml).
This is installed using `kubectl apply -f romana-root-service.yml`

The address specified for `clusterIP` is required for the romana-agent daemonset, and must be within the "service cluster ip range" of your Kubernetes cluster.

### romana-agent daemonset

Each node in the cluster should have a romana-agent pod deployed. This is handled by adding a daemonset.
The agent is responsible for configuring the host environment as pods are created or destroyed, and policies are applied to the cluster.

To install the daemonset, refer to [romana-agent-daemonset.yml](https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-agent-daemonset.yml).
This is installed using `kubectl apply -f romana-agent-daemonset.yml`

#### Mandatory settings

The `--cluster-ip-cidr` must be specified. This should match the kubernetes apiserver setting for `--service-cluster-ip-range`

Example:
- (kops): `--cluster-ip-cidr=100.64.0.0/12`
- (kubeadm): `--cluster-ip-cidr=10.96.0.0/12`

#### Optional settings

- `--romana-root`: The full HTTP address of the root service. Default: none, address discovered from service environment variables
- `--interface`: The interface to use for detecting the host's address. Default: eth0
- `--nat`: Permit pods to reach other networks with NAT (Network Address Translation). Default: true
- `--nat-interface`: The interface traffic will route through when NAT is required. Defaults to `--interface` if specified, or eth0 if unspecified
- `--pod-to-host`: Permit communication between pods and the host they are scheduled on. Required for some services and healthchecks. Default: true
- `--node-name`: The name used for nodes in the cluster. Default: hostname. Permitted values: hostname, fqdn
- `--cloud`: Enable cloud integration. No default. Permitted values: none, aws

# Developer Information

## Requirements for building your own containers

Linux, Docker, internet connection, and a Docker repository. It was developed on Ubuntu 16.04.

The user running the script should be part of the `docker` group.

## Usage

```bash
# Clone the repository
git clone https://github.com/romana/romana
# See the list of options available
romana/containerize/allthethings --help
# Run the script (uses master)
romana/containerize/allthethings
# Build a tagged release
romana/containerize/allthethings --tag=v0.9.3
# Push containers to Docker repositories
romana/containerize/allthethings --tag=v0.9.3 --namespace=quay.io/romana --namespace=otherrepo/romana-
```

## Options

-  `-t (or --tag)`: The git tag to use for `romana/core`. This is also used as the tag for the image. Default is `master` with tag `latest`.
-  `-c (or --compile)`: Compile the binaries from `romana/core`. Default is to compile if they don't exist.
-  `-b (or --build)`: Build the images. Default is to build them if they don't exist.
-  `-p (or --push)`: Push the images. Default is to push them to the namespaces listed.
-  `-n (or --namespace)`: A namespace prefix to use when building images. No default. Can be specified multiple times.
