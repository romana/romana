# Using Romana on Kubernetes

When installation completes, some SSH commands are provided for logging into your new hosts, eg:
```bash
ssh -i /.../romana-install/romana_id_rsa ubuntu@52.xx.yy.zz
ssh -i /.../romana-install/romana_id_rsa ubuntu@54.zz.yy.xx
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
ubuntu@ip-192-168-99-10:~$ romana host list
Host List
Id	 Host Name		 Host IP	 Romana CIDR	 Agent Port	
1 	 ip-192-168-99-10 	 192.168.99.10 	 10.0.0.1/16 	 0 		
2 	 ip-192-168-99-11 	 192.168.99.11 	 10.1.0.1/16 	 0 		
ubuntu@ip-192-168-99-10:~$ romana host show ip-192-168-99-10
Host List
Id	 Host Name		 Host IP	 Romana CIDR	 Agent Port	
1 	 ip-192-168-99-10 	 192.168.99.10 	 10.0.0.1/16 	 0 		
ubuntu@ip-192-168-99-10:~$ romana host show ip-192-168-99-11
Host List
Id	 Host Name		 Host IP	 Romana CIDR	 Agent Port	
2 	 ip-192-168-99-11 	 192.168.99.11 	 10.1.0.1/16 	 0 		
ubuntu@ip-192-168-99-10:~$ 
```
A default install will have two hosts (`192.168.99.10` and `192.168.99.11`). Each host has its own CIDR (`10.0.0.1/16`, `10.1.0.1/16`) that Romana will use when allocating IP addresses to Kubernetes pods on that host.

```sh-session
ubuntu@ip-192-168-99-10:~$ romana tenant list
Tenant List
Id	 Tenant Name	 External ID				
1 	 default 	 4d691d689d8e4c01a5e0b99d49171935 	
2 	 tenant-a 	 dee53ccebaca4adab0f68a9c23e3cbc1 	
ubuntu@ip-192-168-99-10:~$ romana tenant show default
ID	 Tenant Name	 External ID				 Segments 	
1 	 default 	 4d691d689d8e4c01a5e0b99d49171935 	default, 
ubuntu@ip-192-168-99-10:~$ romana tenant show tenant-a
ID	 Tenant Name	 External ID				 Segments 	
2 	 tenant-a 	 dee53ccebaca4adab0f68a9c23e3cbc1 	default, backend, frontend, 
ubuntu@ip-192-168-99-10:~$ 
```

We've also created `default` and `tenant-a` tenants with segments within them. `default` has a single segment, and `tenant-a` only has additional `frontend` and `backend` segments.
When creating new pods, this configuration is used to help construct an IP address within the CIDR allocated to the host.

## Creating new pods

See the example `yaml` files in the `demo` folder. Romana is operating behind-the-scenes of Kubernetes, and gets notified about pods being created, allocating IP addresses and configuring `iptables` rules.

## Details

- See what `iptables` rules were configured: `sudo iptables -nL`
- See routes that were configured: `ip route`
- Log files: these are in `/var/log/upstart/`

## Experiment

Make changes to the setup using the `romana` CLI tool.
- Add new tenant: `romana tenant create <name>`
- Add new segments: `romana segment add <tenant-name> <segment-name>

These tenants and segments can be used when creating Kubernetes resources using kubectl.

Look into the demo script and resources (`.yaml` files) in `~/demo` to see how tenants and segments are applied to Kubernetes resources.
