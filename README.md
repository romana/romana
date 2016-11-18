# The Romana Project

Romana is a new network and security automation solution for Cloud Native applications. Romana automates the creation of isolated Cloud Native Networks and secures applications with a distributed firewall that applies access control policies consistently across all endpoints and services, wherever they run.

# Code

This repository contains the installer and documentation.
The Romana source code, however, is contained in these repositories:

* [core](https://github.com/romana/core ): A number of micro services written in Go, which comprise the core components of the Romana system.
* [kube](https://github.com/romana/kube): The Romana CNI plugin and Network Policy Agents for Kubernetes
* [networking-romana](https://github.com/romana/networking-romana): The Romana ML2 plugin and IPAM driver for OpenStack

The READMEs of those repos contain more information about the source code and how to run and test it.

#  Installation

To get up and running with Romana, some scripts and Ansible playbooks have been provided to automate the setup and deployment.
This can be used to set up a cluster for experimenting with Romana, exploring how it works and learning how it interacts with Kubernetes and/or Openstack.

The installer is currently capable of setting up a stand-alone [Kubernetes](http://kubernetes.io) or [OpenStack-Devstack](http://docs.openstack.org/developer/devstack/) cluster. 
As deployment targets for those clusters, it supports [Amazon EC2](https://aws.amazon.com/ec2/), local [Vagrant](https://www.vagrantup.com/) VMs, or user-provided ("static") hosts.

* [Romana on AWS EC2 with Kubernetes](aws_kubernetes.md)
* [Romana on AWS EC2 with Devstack](aws_devstack.md)
* [Romana on Vagrant VMs with Kubernetes](vagrant_kubernetes.md)
* [Romana on Vagrant VMs with Devstack](vagrant_devstack.md)
* [Romana on User-Provided Hosts](static_hosts.md)

See the [`romana-setup` page](romana_setup.md) for details about the installer and the full set of command-line options available.

If you wish to install Romana as a Kubernetes [add-on using kubeadm](http://kubernetes.io/docs/getting-started-guides/kubeadm/), or use [kops](http://kubernetes.io/docs/getting-started-guides/kops/) for installation on EC2, see the [README](containerize) file in the containerize directory.

Additional installation platforms are being targeted.
You can express your interest in specific platforms or get help with manually installing Romana by [contacting us](#contact-us).

# Using Romana

Once you have Romana installed and running in a cluster, you might like to test its capabilities and see it in action.
The two links below give you cluster specific suggestions of what to try and what to explore and look at.

* [Romana with Kubernetes](kubernetes_romana.md)
* [Romana with Devstack](devstack_romana.md)

# Contact Us

There are a number of ways in which you can contact us if you have any questions about deploying or using Romana,
or about contributing to our code.

* By email: [info@romana.io](mailto:info@romana.io)
* Via our [Romana developer mailing list](https://groups.google.com/forum/?hl=en#!forum/romana-dev)
* Via our [Romana user mailing list](https://groups.google.com/forum/?hl=en#!forum/romana-user)
* On the [Romana Slack channel](https://romana.slack.com/). Please note that you will need an invite for this channel. Please contact us [by email](mailto:info@romana.io) to request an invite
