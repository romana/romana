# The `romana-setup` tool

The `romana-setup` tool is used to provision and install Romana using the selected installation environment, linux distribution and stack type.

## Usage Summary

```
romana-setup: executes the ansible playbooks for installing romana
Usage: romana-setup [-n name] [-p platform] [-d distro] [-s stacktype] [action]
       romana-setup [-n name] [-p platform] [-d distro] [-s stacktype] <action> [ansible-options]
       romana-setup <h|--help>

Stack Name:  user-defined stack name (default: $USER)
Platforms:   aws (default), vagrant
Distro:      ubuntu (default), centos
Stack Types: devstack (default), kubernetes
Actions:     install (default), uninstall
```

## Option Details

### Name

A name for the installation environment can be specified using the `-n` or `--name` option.
The name must contain only ASCII letters and digits, and start with a letter.

If not specified, the value of `$USER` is used.
You should specify this option if you:
- create multiple installs using `romana-setup`
- do not have `USER` set to a valid value
- prefer a different name for items created by `romana-setup`

### Platform

A platform can be specified using the `-p` or `--platform` option. `romana-setup` will use this to create hosts or virtual machines prior to installing the stack and Romana components.

Valid values are:
- `aws` -- a set of EC2 instances created in Amazon Web Services (AWS) using CloudFormation
- `vagrant` -- a group of VirtualBox VMs created using Vagrant

### Distro

The linux distribution can be specified using the `-d` or `--distro` option.
This is used when the installation environment is created, and when stack and Romana components are being installed.

Valid values are:
- `ubuntu` -- [Ubuntu](http://www.ubuntu.com/) 14.04 LTS
- `centos` -- [Centos](https://www.centos.org/) 7

### Stack Types

The type of stack can be specified using the `-s` or `--stack` option.
This is installed and configured by `romana-setup` to use Romana components. After the installation is completed, the stack is ready to use.

Valid values are:
- `devstack` -- [OpenStack](http://www.openstack.org/) stable/liberty installed using [devstack](https://github.com/openstack-dev/devstack)
- `kubernetes` -- [Kubernetes](http://kubernetes.io/)
