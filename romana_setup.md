# The `romana-setup` tool

The `romana-setup` tool is used to provision and install Romana using the selected installation environment, Linux distribution and stack type.

This can be used to set up small clusters running Romana on AWS, Vagrant or predefined hosts for testing, evaluation and demonstration purposes.

## Usage Summary

```
romana-setup: executes the ansible playbooks for installing romana
Usage: romana-setup [-n name] [-p platform] [-d distro] [-s stacktype] [action]
       romana-setup [-n name] [-p platform] [-d distro] [-s stacktype] <action> [ansible-options]
       romana-setup <h|--help>

Cluster Name:  user-defined stack name (default: $USER)
Platforms:     aws (default), vagrant, static
Distro:        ubuntu (default), centos
Stack Types:   devstack (default), kubernetes
Actions:       install (default), uninstall
```

## Option Details

### Cluster Name

A name for the cluster can be specified using the `-n` or `--name` option.
The name must contain only ASCII letters and digits, and start with a letter.

If not specified, the value of `$USER` is used.
You should specify this option if you:
- create multiple clusters using `romana-setup`
- do not have `USER` set to a valid value
- prefer a different name for items created by `romana-setup`

### Platform

A platform can be specified using the `-p` or `--platform` option. This specifies whether `romana-setup` will create the cluster or use predefined hosts.

Valid values are:
- `aws` -- a set of EC2 instances created in Amazon Web Services (AWS) using CloudFormation
- `vagrant` -- a group of VirtualBox VMs created using Vagrant
- `static` -- predefined hosts created outside of this tool (refer to [this page](static_hosts.md) for additional details)

**Note**: Vagrant installs automatically configure a Host-Only Network for the VMs, with a predefined subnet of `192.168.99.0/24`.
If multiple installs are being performed on the same host, you will need to override this value.
See the [example](#examples) for this.

### Distro

The Linux distribution can be specified using the `-d` or `--distro` option.
This is used when the installation environment is created, and when stack and Romana components are being installed.

Valid values are:
- `ubuntu` -- [Ubuntu](http://www.ubuntu.com/) 14.04 LTS
- `centos` -- [Centos](https://www.centos.org/) 7

**Note**: Centos 7 on AWS requires accepting the License Agreement in the [AWS Marketplace](http://aws.amazon.com/marketplace/pp?sku=aw0evgkw8e5c1q413zgy5pjce).

### Stack Types

The type of stack can be specified using the `-s` or `--stack` option.
This is installed and configured by `romana-setup` to use Romana components. After the installation is completed, the stack is ready to use.

Valid values are:
- `devstack` -- [OpenStack](http://www.openstack.org/) stable/liberty installed using [devstack](https://github.com/openstack-dev/devstack)
- `kubernetes` -- [Kubernetes](http://kubernetes.io/) v1.2

## Action Details

### Install

The `install` action performs a number of steps, creating the hosts with the selected Linux distribution (`aws` and `vagrant` only), installing the requested type of stack, and installing and configuring Romana for that stack. Once completed, a summary is provided with details you can copy-and-paste to connect to the hosts and begin using the stack.

### Uninstall

The `uninstall` action is used to delete hosts created during install (`aws` and `vagrant` only), and remove local files created by the installer. (It does not remove only Romana components from the hosts.)

## Ansible Options

In some cases, you may wish to pass additional options to Ansible for the installation.

You can do this by either:
* Editing values in `romana-install/group_vars` files
* Providing ansible options at the end of the `romana-setup` command

All items on the command-line after the `install` or `uninstall` verb are passed to Ansible.

An example [example](#examples) can be seen below.

## Examples

### AWS - Ubuntu - Devstack

```bash
cd romana-install
# Install
./romana-setup -n example01 -p aws -d ubuntu -s devstack install
# Uninstall
./romana-setup -n example01 -p aws -d ubuntu -s devstack uninstall
```

Because this is the default, most options can be omitted.
```bash
./romana-setup -n example01 install
./romana-setup -n example01 uninstall
```

### Vagrant - Centos - Kubernetes

```bash
cd romana-install
./romana-setup -n example02 -p vagrant -d centos -s kubernetes install
./romana-setup -n example02 -p vagrant -d centos -s kubernetes uninstall
```

### Vagrant - Unique Host CIDR

```bash
cd romana-install
./romana-setup -n example03 -p vagrant -d centos -s kubernetes install -e host_cidr="192.168.88.0/24"
./romana-setup -n example03 -p vagrant -d centos -s kubernetes uninstall -e host_cidr="192.168.88.0/24"
```
