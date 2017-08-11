# Romana on Kubernetes

# Installation

Installing Romana on a Kubernetes cluster is fast and easy.

For clusters created with `kops` or `kubeadm` with default settings, predefined YAML files are provided that you can install using `kubectl apply`.
Some changes to the YAML files will be required under some circumstances. Please check the special notes.

## Installation for kubeadm

Follow the guide for [Using kubeadm to Create a Cluster](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#instructions), and complete steps 1 and 2.
Then, to install Romana, run
```bash
kubectl apply -f https://raw.githubusercontent.com/romana/romana/romana-2.0/docs/kubernetes/romana-kubeadm.yml
```

Please see special notes below if
- you are using a non-default range for Kubernetes Service IPs
- want to specify your own IP range for Pod IPs
- are running in virtualbox
- have cluster nodes in multiple subnets

## Installation for kops

**NOTE:** These instructions will change in the near future, when Romana is added as a built-in networking option in `kops`.

When creating your kops cluster, use the `--networking cni` option.
You will need to SSH directly to your master node to install Romana and have the rest of the cluster finish launching.

```bash
# Connect to the master node
ssh admin@master-ip
# Check that Kubernetes is running and that the master is in NotReady state
kubectl get nodes
```

You should see output similar to the below example.
```
NAME                                          STATUS            AGE       VERSION
ip-172-20-xx-xxx.us-west-2.compute.internal   NotReady,master   2m        v1.7.0
```

Then, to install Romana, run
```bash
kubectl apply -f https://raw.githubusercontent.com/romana/romana/romana-2.0/docs/kubernetes/romana-kops.yml
```

It will take a few minutes for the master node to become ready, launch deployments, and for other minion nodes to register and activate.

The install for kops provides two additional components:
- romana-aws: A tool that automatically configures EC2 Source-Dest-Check attributes for nodes in your Kubernetes cluster
- romana-vpcrouter: A service that populates your cluster's VPC Routing tables with routes between AZs.

Please see special notes below if
- you are using a non-default range for Kubernetes Service IPs
- want to specify your own IP range for Pod IPs 

## Installation in other environments

If you are using a different installer or have your own set of tools for bringing up a cluster, it is likely that the predefined configurations for kubeadm or kops will not work.
Instead, it is usually necessary to customize the YAML files used for the installing Romana to match your environment.

More information about this will be added in a future update. In the meantime, we can help via email or Slack.

# Updates coming soon

These topics still need additional explanation, instructions and guides.

- Essential Components
- romana-etc
  - romana-daemon
  - romana-listener
  - romana-agent
- Add-Ons
  - romana-aws
  - romana-vpcrouter
- Special Notes
  - Custom range for Kubernetes Service IPs
  - Custom range for Pod IPs
  - Running in VirtualBox
  - Running in multiple subnets
