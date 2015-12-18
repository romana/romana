# The Romana Project


# Getting Started

To get started with Romana running on Devstack, some Ansible playbooks have been provided to automate the setup and deployment.

## Romana on Amazon EC2 Instances

Before you start, you will need to install the appropriate tools, and configure SSH and AWS credentials.

### Tools

This setup requires ansible v1.9.x, so for Ubuntu 14.04 LTS, you will need to add this PPA (Personal Package Archive).
```bash
sudo add-apt-repository ppa:ansible/ansible
sudo apt-get update
```

Install ansible and boto.

```bash
sudo apt-get install ansible python-boto
```

Check out Romana repository.
```bash
git clone https://github.com/romana/romana
```
Run the installer. This will create the Devstack cluster, install and activate Romana Cloud-Native tools.
```bash
cd romana/romana-install
./romana-setup
```

To uninstall, use the 'uninstall' subcommand.
```bash
./romana-setup uninstall
```

Some options are available within ``romana/romana-install/group_vars/all`` that can be adjusted.
These can also be passed to the romana-setup command as Ansible extra-options, eg:
```bash
./romana-setup install -e devstack_name=xyz_demo
./romana-setup uninstall -e devstack_name=xyz_demo
```

## Romana on Virtualbox VMs

Under development.


