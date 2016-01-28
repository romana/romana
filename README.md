# The Romana Project

Romana is a new Software Defined Network (SDN) solution specifically designed
for the Cloud Native architectural style. The result of this focus is that
Romana cloud networks are less expensive to build, easier to operate and
deliver higher performance than cloud networks built using alternative SDN
designs.

# Getting Started

To get started with Romana running on Devstack, some scripts and Ansible
playbooks have been provided to automate the setup and deployment. These are
located in this repository. They will access other repositories to download
required pieces of the Romana system, as well as some binaries we have already
pre-compiled for your convenience.

The setup described below has been tested on Ubuntu 14.04 LTS, but should work
similarly on other Linux or Mac OS X environments.

## Romana on Amazon EC2 Instances

Before you start, you will need to install the appropriate tools, and configure
SSH and AWS credentials.

### Tools

This setup requires ansible v1.9.3+ and boto. It is generally best to install these via python's ``pip`` tool.
```bash
sudo apt-get install git python-pip python-dev
sudo pip install ansible==1.9.4 boto awscli
```

This setup expects certain keys in specific locations.
- Your SSH private key in `~/.ssh/id_rsa`
- Your SSH public key in `~/.ssh/id_rsa.pub`
- Your EC2 Private Key in `~/.ssh/ec2_id_rsa`

Note: your SSH keys are used to access Github and checkout Romana's private repositories.
It will not be necessary to provide these when the repositories are made public.

Configure awscli with your AWS Credentials.
```bash-session
$ aws configure
AWS Access Key ID [None]: A*******************
AWS Secret Access Key [None]: ****************************************
Default region name [None]: us-west-1
Default output format [None]: 
```
Note: The credentials provided should permit the creation of AWS resources such as EC2 instances, VPCs and so on.
Ensure the IAM user or role for these credentials has permission to create these AWS resources.

Note: The installation currently expects region ``us-west-1``, and might not work in other regions.
This will be addressed in the future.


Confirm your SSH keys allow you to access github.
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
cd romana/romana-install
```

Edit the `group_vars/all` file to specify the appropriate EC2 Key Name.
Eg: change the `key_name` item from `shared-key-1` to the name you have configured.
You can check the name in AWS by opening the EC2 dashboard, and selecting "Key Pairs" to see your list of Key pair names.

Run the installer. This will create the Devstack cluster, install and activate Romana Cloud-Native tools.
```bash
./romana-setup
```

The EC2 installation takes 20-25 mins to complete (on t2.large instances) and creates an OpenStack DevStack cluster (Liberty release) with a single Controller Node and up to 4 Compute Nodes. Each OpenStack Node runs on a dedicated EC2 instance. Romana installs its OpenStack ML2 and IPAM drivers and creates a Romana router gateway interface on each Compute Node.

Once installed, you can perform a variety of checks and experiments on your own. See the [Wiki](https://github.com/romana/romana/wiki) for details.

To uninstall, use the 'uninstall' subcommand.
```bash
./romana-setup uninstall
```

Some options are available within ``romana/romana-install/group_vars/all`` that can be adjusted.
These can also be passed to the romana-setup command as Ansible extra-options, eg:
```bash
./romana-setup install -e devstack_name=xyzdemo
./romana-setup uninstall -e devstack_name=xyzdemo
```

Note: the name should be one word, and only contain letters and numbers. (No hyphens, underscores, etc).

### Use

- connect to your host: `ssh -i ~/.ssh/ec2_id_rsa ubuntu@controller-ip`
- launch an instance using Horizon:
  * Open http://controller-ip/
  * Log into the dashboard using username `admin` and password `secrete` (or the password you configured before installation)
  * Select `Instances` from the `Project/Compute` sidebar
  * Click the `Launch Instance` button
  * Provide the required details
  * Optionally, select the Advanced tab and specify a segment name in the `Romana Network Segment` field
  * Click the Launch button
- launch an instance using command-line: `nova boot --flavor m1.tiny --image cirros-0.3.4-x86_64-uec --nic net-id=$(neutron net-show romana -Fid -f value) --meta romanaSegment=default instance-name`
- connect to the instance: `ssh cirros@instance-ip`
- install an ubuntu image:
  * Create a new flavor with RAM:512MB, Disk: 3GB, VCPUs: 1: `nova flavor-create m1.smallish auto 512 3 1`
  * Download a suitable image: `wget https://cloud-images.ubuntu.com/releases/14.04.3/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img`
  * Create image: `glance image-create --visibility public --disk-format qcow2 --container-format bare --name "ubuntu" < ubuntu-14.04-server-cloudimg-amd64-disk1.img`
- register a new host: on the controller, run `romana add-host <hostname> <host-ip> <romana-cidr> <agent-port>`
- add a new tenant: on the controller, run `romana create-tenant <tenant-name>`
- add a new segment: on the controller, run `romana add-segment <tenant-name> <segment-name>`
- see a list of tenants: `romana show-tenant`, details for a specific tenant: `romana show-tenant <tenant-name>`
- see a list of hosts: `romana show-host`, details for a specific host: `romana show-host <hostname>`

See also: [Try Romana Now](http://romana.io/try_romana/#what-you-can-do)

## Romana on Virtualbox VMs

Under development.

## Working with the code

This repository here contains the demo installer and documentation. The actual
source code, however, is contained in these two repositories:

* [core](https://github.com/romana/core ): A number of micro services written in Go, which comprise the core components of the Romana system.
* [networking-romana](https://github.com/romana/networking-romana): The Romana ML2 plugin an IPAM driver for OpenStack.

The READMEs of those repos contain more information about the source code and
how to run and test it.

