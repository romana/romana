# Installing Romana on static hosts

The `romana-setup` tool allows you to provide a list of hosts that were provisioned manually or with other tools, and perform the installation on those hosts.

This is done by providing an Ansible `inventory` file when running the `romana-setup` command.

Each host needs to sastisfy the minimum requirements before the installtion can be performed.

## Minimum Requirements

- A Redhat- or Debian-based linux distribution installed
- Access to the internet for downloading additional files
- Access to other hosts via the same network segment
- An unprivileged user with `sudo` access
- `sudo` not requiring a password for that unprivileged user
- `sudo` configured to not require a TTY 
- Key-based SSH access for that unprivileged user
- Python installed
- Python packages for the distro package manager installed (eg: `python-apt`, `python-yum`)

## Inventory file

The inventory file provides the list of hosts to use for installation, the details required to connect to them, and the role of the host.

```
example-controller ansible_ssh_host="192.168.10.10" ansible_ssh_user="ubuntu" ansible_ssh_private_key_file="/home/example/example_id_rsa" stack_host="Controller"
example-compute01  ansible_ssh_host="192.168.10.11" ansible_ssh_user="ubuntu" ansible_ssh_private_key_file="/home/example/example_id_rsa" stack_host="Compute01"
# Additional compute hosts may be specified here, eg
# example-compute02  ansible_ssh_host="192.168.10.02" ansible_ssh_user="ubuntu" ansible_ssh_private_key_file="/home/example/example_id_rsa" stack_host="Compute02"
# example-compute03  ansible_ssh_host="192.168.10.03" ansible_ssh_user="ubuntu" ansible_ssh_private_key_file="/home/example/example_id_rsa" stack_host="Compute03"
# example-compute04  ansible_ssh_host="192.168.10.04" ansible_ssh_user="ubuntu" ansible_ssh_private_key_file="/home/example/example_id_rsa" stack_host="Compute04"

[stack_nodes:children]
controller
computes

[controller]
example-controller

[computes]
example-compute01
# The names of additional compute hosts should be put here also, eg
# example-compute02
# example-compute03
# example-compute04
```

## Installation

Run the installation, specifying `-p static` and the path to the inventory file using `-i /path/to/inventory`.

```bash
cd romana-install
./romana-setup -n example -p static -i /path/to/inventory -d ubuntu -s kubernetes install
```


## Uninstallation

This should be performed manually, or using the provisioning tools used to create the hosts.
Running the `uninstall` command cleans up local files created during installation but does no other action on the hosts.
