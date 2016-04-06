# Installing Romana on AWS EC2 with Devstack

The setup described below has been tested on Ubuntu 14.04 LTS, but should work similarly on other Linux or Mac OS X environments.
You may need to install additional development tools.

If you do not wish to install additional tools in your host, you can create a VM and execute the installation steps from there.

# Prepare

To run this installation, you will need
* an AWS account. You can create one at [http://aws.amazon.com](http://aws.amazon.com)
* credentials for an [AWS IAM](https://console.aws.amazon.com/iam/home) User/Role that permits creating EC2 instances
* [ansible](https://www.ansible.com) v2.0.1 or higher, and supporting python tools / libraries

## Set up Ansible

```bash
# Ubuntu
sudo apt-get install git python-pip python-dev
sudo pip install ansible boto awscli netaddr

# OS X
sudo easy_install pip
sudo pip install ansible boto awscli netaddr
```

## Set up AWS tools

```bash
aws configure
```

This will prompt you for your AWS Access Key ID, AWS Secret Key ID and Region.

```sh-session
AWS Access Key ID [None]: A*******************
AWS Secret Access Key [None]: ****************************************
Default region name [None]: us-west-1
Default output format [None]: 
```

## (Optional) Set up EC2 Key Pair

If the servers will be accessed by people using an [EC2 Key Pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html), apply the additional configuration step.
```bash
# Configure 'shared-key-1' as the EC2 Key Pair used by the installer
echo "shared-key-1" > ~/.aws/ec2_keypair
```

# Install

Check out the Romana repository and run the installer
```bash
git clone https://github.com/romana/romana
cd romana/romana-install
./romana-setup -p aws -s devstack install
```

The EC2 installation takes 20-25 mins to complete, and creates a Devstack cluster with two nodes. When installation is complete, information about the cluster should be provided.
```sh-session
Devstack Summary
================

Controller
----------
IP: 52.xx.yy.zz
http://52.xx.yy.zz
(username: admin, password: secrete)
ssh -i /.../romana-install/romana_id_rsa ubuntu@52.xx.yy.zz

Other Nodes
-----------
ssh -i /.../romana/romana-install/romana_id_rsa ubuntu@54.zz.yy.xx
```

You can now proceed to [Using Romana on Devstack](devstack_romana.md).

# Uninstall

From the same directory, you can perform an uninstall
```bash
./romana-setup -p aws -s devstack install
```

This will destroy the Devstack cluster.
