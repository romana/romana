# Romana on Kubernetes

# Installation

Installing Romana on a Kubernetes cluster is fast and easy.

For clusters created with `kops` or `kubeadm` with default settings, predefined YAML files are provided that you can install using `kubectl apply`.
Some changes to the YAML files will be required under some circumstances - check the special notes below.

If you have made your own customized installation of Kubernetes or used a different tool to create the cluster, then you should refer to the detailed [components](components.md) page, and align the example configuration with the details specific to your cluster.

## Installation for kubeadm

Follow the guide for [Using kubeadm to Create a Cluster](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#instructions), and complete steps 1 and 2.
Then, to install Romana, run
```bash
kubectl apply -f https://raw.githubusercontent.com/romana/romana/master/docs/kubernetes/romana-kubeadm.yml
```

Please see special notes below if
- you are using a non-default range for Kubernetes Service IPs
- want to specify your own IP range for Pod IPs
- are running in virtualbox
- have cluster nodes in multiple subnets

## Installation for kops

**NOTE:** These instructions will change in the near future, when Romana is added as a built-in networking option in `kops`.

When creating your [kops cluster](https://github.com/kubernetes/kops/blob/master/docs/aws.md), use the `--networking cni` option.
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
kubectl apply -f https://raw.githubusercontent.com/romana/romana/master/docs/kubernetes/romana-kops.yml
```

It will take a few minutes for the master node to become ready, launch deployments, and for other minion nodes to register and activate.

You will also need to open port 4001 in the AWS Security Group for your "masters" instances. This can be edited in the AWS EC2 Management Console.
Edit the rule for TCP Ports 1-4000 from "nodes", and change the range to 1-4001.

The install for kops provides two additional components:
- romana-aws: A tool that automatically configures EC2 Source-Dest-Check attributes for nodes in your Kubernetes cluster
- romana-vpcrouter: A service that populates your cluster's VPC Routing tables with routes between AZs.

Please see special notes below if
- you are using a non-default range for Kubernetes Service IPs
- want to specify your own IP range for Pod IPs 

## Installation in other environments

Please refer to the detailed [components](components.md) page, and align the example configuration with the details specific to your cluster.

# Updates coming soon

These topics still need additional explanation, instructions and guides.

- Special Notes
  - Custom range for Kubernetes Service IPs
  - Custom range for Pod IPs
  - Running in VirtualBox
  - Running in multiple subnets
