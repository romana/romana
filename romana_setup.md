# The `romana-setup` tool

The `romana-setup` tool is used to provision an installation environment for Romana, using the selected platform, linux distribution and cluster stack.

## Usage Summary

```
romana-setup: executes the ansible playbooks for installing romana
Usage: romana-setup [-n stackname] [-p platform ] [ -d distro ] [-s stacktype] [action]
       romana-setup [-n stackname] [-p platform ] [ -d distro ] [-s stacktype] <action> [ansible-options]
       romana-setup <h|--help>

Stack Name:  user-defined stack name (default: cgilmour)
Platforms:   aws (default), vagrant
Distro:      ubuntu (default), centos
Stack Types: devstack (default), kubernetes
Actions:     install (default), uninstall
```

## Option Details

### Stack Name

A name for the stack can be spefied using the `-n` or `--name` option.
The name must contain only ASCII letters and digits, and start with letter.

If not specified, the value of `$USER` is used.
You should specify this option if you are
- creating multiple clusters with `romana-setup`
- do not have `USER` set to a valid value
- prefer a different name for items created by `romana-setup`

### Platform

The name of the platform that `romana-setup` will provision.

Valid platforms are:
- `aws` -- a set of EC2 instances created in Amazon Web Services (AWS) using CloudFormation
- `vagrant` -- a group of VirtualBox VMs created using Vagrant

### Distro

The linux distribution that the cluster stack and Romana will be installed on.

Valid distros are:
- `ubuntu` -- [Ubuntu](http://www.ubuntu.com/) 14.04 LTS
- `centos` -- [Centos](https://www.centos.org/) 7

### Stack Types

The type of cluster stack that will be installed.

Valid values are:
- `devstack` -- [OpenStack](http://www.openstack.org/) stable/liberty installed using [devstack](https://github.com/openstack-dev/devstack)
- `kubernetes` -- [Kubernetes](http://kubernetes.io/)
