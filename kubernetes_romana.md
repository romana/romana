# Using Romana on Kubernetes

When installation completes, some SSH commands are provided for logging into your new hosts, eg:
```bash
ssh -i /.../romana-install/romana_id_rsa ubuntu@52.xx.yy.zz
ssh -i /.../romana/romana-install/romana_id_rsa ubuntu@54.zz.yy.xx
```

These can be used to log into the host using the generated SSH key. Use the SSH command for the master to log in.

## Run a scripted demo

We've provided a scripted demo, for a quick introduction to Romana on Kubernetes. Use this command to run it.
```bash
ubuntu@ip-192-168-99-10:~$ ./demo/demo.sh 
```

Press Enter to proceed through the steps.

## Look up information

A `romana` command-line tool has been provided that lets you see details about the setup, and make changes.
```sh-session
ubuntu@ip-192-168-99-10:~$ romana show-hosts
Listing 2 host(s)
ip-192-168-99-10
ip-192-168-99-11
ubuntu@ip-192-168-99-10:~$ romana show-host ip-192-168-99-10
ip-192-168-99-10       192.168.99.10        10.0.0.1/16     0
ubuntu@ip-192-168-99-10:~$ romana show-host ip-192-168-99-11
ip-192-168-99-11       192.168.99.11        10.1.0.1/16     0
```
By default, we have two hosts (`192.168.99.10` and `192.168.99.11`). Each host has its own CIDR (`10.0.0.1/16`, `10.1.0.1/16`) that Romana will use when allocating IP addresses to Kubernetes pods on that host.

```sh-session
ubuntu@ip-192-168-99-10:~$ romana show-owners
Listing 2 owner(s)
t1                              
t2                              
ubuntu@ip-192-168-99-10:~$ romana show-owner t1
owner:t1                              
tiers: default, backend, frontend
ubuntu@ip-192-168-99-10:~$ romana show-owner t2
owner:t2                              
tiers: default
ubuntu@ip-192-168-99-10:~$ 
```

We've also created `t1` and `t2` owners with tiers within them. `t1` has three tiers, and `t2` only has a default tier.
When creating new pods, this configuration is used to help construct an IP address within the CIDR allocated to the host.

## Creating new pods

See the example `yaml` files in the `demo` folder. Romana is operating behind-the-scenes of Kubernetes, and gets notified about pods being created, allocating IP addresses and configuring `iptables` rules.

## Details

- See what `iptables` rules were configured: `sudo iptables -nL`
- See routes that were configured: `ip route`
- Log files: these are in `/var/log/upstart/`

## Experiment

Make changes to the setup using the `romana` CLI tool.
- Add new owners: `romana create-owner <name>`
- Add new tiers: `romana add-tier <owner> <tier-name>

These owners and tiers can be used when creating Kubernetes resources using kubectl.

Look into the demo script and resources (`.yaml` files) in `~/demo` to see how owners and tiers are applied to Kubernetes resources.
