# The Romana Project


# Getting Started

To get started with Romana running on Devstack, some Ansible playbooks have been provided to automate the setup and deployment.

## Romana on Amazon EC2 Instances

Before you start, you will need to install the appropriate tools, and configure SSH and AWS credentials.

### Tools

This setup requires ansible v1.9.3+ and boto. It is generally best to install these via python's ``pip`` tool.
```bash
sudo apt-get install git python-pip python-dev
sudo pip install ansible boto awscli
```

Copy your EC2 SSH key into the expected location.
```bash
cp /path/to/ec2_ssh_private_key ~/.ssh/ec2_id_rsa
chmod 0600 ~/.ssh/ec2_id_rsa
```

Configure awscli with your AWS Credentials
```bash-session
$ aws configure
AWS Access Key ID [None]: A*******************
AWS Secret Access Key [None]: ****************************************
Default region name [None]: us-west-1
Default output format [None]: 
```
Note: The installation currently expects region ``us-west-1``, and might not work in other regions.
This will be addressed in the future.

Confirm you have the appropriate Github keys available
```bash-session
$ ssh git@github.com
PTY allocation request failed on channel 0
Hi your-github-username! You've successfully authenticated, but GitHub does not provide shell access.
Connection to github.com closed.
```

### Install

Check out Romana repository.
```bash
git clone git@github.com:romana/romana
```

Run the installer. This will create the Devstack cluster, install and activate Romana Cloud-Native tools.
```bash
cd romana/romana-install
./romana-setup
```

The EC2 installation takes 30-40 min to complete (on t2.medium instances) and creates an OpenStack DevStack cluster (Liberty release) with a single Controller Node and up to 4 Compute Nodes. Each OpenStack Node runs on a dedicated EC2 instance. Romana installs its OpenStack ML2 and IPAM drivers and creates a Romana router gateway interface on each Compute Node.

Once installed, you can perform a variety of checks and experiments on your own. See the [Wiki](https://github.com/romana/romana/wiki) for details.

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


