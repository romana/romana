# Installing Romana on Vagrant with Devstack

The setup described below has been tested on Ubuntu 14.04 LTS, but should work similarly on other Linux or Mac OS X environments.
You may need to install additional development tools.

This should be done on your host. A 'run from a VM' option is being developed, for users that do not wish to install additional tools on the host.

# Prepare

To run this installation, you will need
* [Vagrant](https://www.vagrantup.com/downloads.html) installed (and [tested](https://www.vagrantup.com/docs/getting-started/) to be sure it works)
* [ansible](https://www.ansible.com) and supporting python tools / libraries

## Set up Ansible

```bash
# Ubuntu
sudo apt-get install git python-pip python-dev
sudo pip install ansible==1.9.4 netaddr

# OS X
sudo easy_install pip
sudo pip install ansible==1.9.4 netaddr
```

# Install

Check out the Romana repository and run the installer
```bash
git clone https://github.com/romana/romana
cd romana/romana-install
./romana-setup -p vagrant -s devstack install
```

The Vagrant installation can take a long time to complete, because of some large downloads that are performed. Please be patient. When installation is complete, information about the cluster should be provided.
```sh-session
Devstack Summary
================

Controller
----------
IP: 52.xx.yy.zz
http://52.xx.yy.zz
(username: admin, password: secrete)
ssh -i /Users/cgilmour/Development/romana/romana/romana-install/romana_id_rsa ubuntu@52.xx.yy.zz

Other Nodes
-----------
ssh -i /Users/cgilmour/Development/romana/romana/romana-install/romana_id_rsa ubuntu@54.zz.yy.xx
```

You can now proceed to [Using Romana on Devstack](romana_devstack.md).

# Uninstall

From the same directory, you can perform an uninstall
```bash
./romana-setup -p vagrant -s devstack install
```

This will destroy the Devstack cluster.
