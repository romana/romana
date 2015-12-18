# The Romana Project


# Getting Started

To get started with Romana running on Devstack, some Ansible playbooks have been provided to automate the setup and deployment.

## Romana on Amazon EC2 Instances

Before you start, you will need to install the appropriate tools, and configure SSH and AWS credentials.

### Tools

This setup requires ansible v1.9.3+, so for Ubuntu, you will need to add this PPA (Personal Package Archive).
```bash
sudo add-apt-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible python-boto awscli
```

Copy your EC2 SSH key into the expected location.
```bash
cp /path/to/ec2_ssh_private_key ~/.ssh/ec2_id_rsa
chmod 0600 ~/.ssh/ec2_id_rsa
```

Configure awscli with your AWS Credentials
```bash session
$ aws configure
AWS Access Key ID [None]: A*******************
AWS Secret Access Key [None]: ****************************************
Default region name [None]: us-west-1
Default output format [None]: 
```
Note: The installation currently expects region ``us-west-1``, and might not work in other regions.
This will be addressed in the future.

Confirm you have the appropriate Github keys available
```bash session
$ ssh git@github.com
PTY allocation request failed on channel 0
Hi your-github-username! You've successfully authenticated, but GitHub does not provide shell access.
Connection to github.com closed.
```

### Install

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


