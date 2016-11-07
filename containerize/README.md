# Containerize

![containerize all the things](https://cdn.meme.am/instances/500x/65415534.jpg)

A script to containerize the Romana applications and example Kubernetes Manifest and DaemonSet for installation.

# Requirements

Linux, Docker, internet connection. It was developed on Ubuntu 16.04.

The user running the script should be part of the `docker` group.

# Usage

```bash
# Clone the repository
git clone https://github.com/romana/romana
# Run the script (uses master)
romana/containerize/allthethings
# Build a tagged release
romana/containerize/allthethings --tag=v0.9.3
```

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

# TODO

* By default, the script will try to push containers to `quay.io/romana`. Disable that with `--push=no`. An option for specifying a different user/org should be added.

