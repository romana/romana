# Using Romana on Devstack

When installation completes, some SSH commands are provided for logging into your new hosts, eg:
```bash
ssh -i /.../romana-install/romana_id_rsa ubuntu@52.xx.yy.zz
ssh -i /.../romana-install/romana_id_rsa ubuntu@54.zz.yy.xx
```

These can be used to log into the host using the generated SSH key. Use the SSH command for the controller to log in.

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
A default install will have two hosts (`192.168.99.10` and `192.168.99.11`). Each host has its own CIDR (`10.0.0.1/16`, `10.1.0.1/16`) that Romana will use when allocating IP addresses to OpenStack instances on that host.

```sh-session
ubuntu@ip-192-168-99-10:~$ romana tenant list
Tenant List
Id	 Tenant Name	 External ID				
1 	 admin 		 310a8620208744049f6c860fd5cb5bb2 	
2 	 demo 		 6aa810e7cb414387afd332cbedb52f57 	
ubuntu@ip-192-168-99-10:~$ romana tenant show admin
ID	 Tenant Name	 External ID				 Segments 	
1 	 admin 		 310a8620208744049f6c860fd5cb5bb2 	default, frontend, backend, 
ubuntu@ip-192-168-99-10:~$ romana tenant show demo
ID	 Tenant Name	 External ID				 Segments 	
2 	 demo 		 6aa810e7cb414387afd332cbedb52f57 	default, frontend, backend, 
ubuntu@ip-192-168-99-10:~$ 
```

We've also created `admin` and `demo` tenants, with three segments: `default`, `frontend`, and `backend`. If a new instance is created for a tenant, a segment name needs to be provided.
This will create an IP address within that segment and configure `iptables` rules to restrict communication to hosts within that segment.

## Create a new instance

When creating an instance, you should provide additional metadata to specify the segment that the instance should be allocated into.
```sh-session
ubuntu@ip-192-168-99-10:~$ nova boot --flavor m1.nano --image cirros-0.3.4-x86_64-uec --key-name shared-key --nic net-id=$(neutron net-show romana -Fid -f value) --meta romanaSegment=default example-instance
+--------------------------------------+----------------------------------------------------------------+
| Property                             | Value                                                          |
+--------------------------------------+----------------------------------------------------------------+
| ...                                  |                                                                |
| created                              | 2016-03-02T22:46:38Z                                           |
| flavor                               | m1.nano (42)                                                   |
| ...                                  |                                                                |
| id                                   | 048054fe-ec19-45ff-a679-83c19ebb5026                           |
| image                                | cirros-0.3.4-x86_64-uec (c11f6cde-7bb8-40ed-bce8-fedf676ef1ff) |
| ...                                  |                                                                |
| metadata                             | {"romanaSegment": "default"}                                   |
| name                                 | example-instance                                               |
| ...                                  |                                                                |
+--------------------------------------+----------------------------------------------------------------+
ubuntu@ip-192-168-99-10:~$ nova list
+--------------------------------------+------------------+--------+------------+-------------+------------------+
| ID                                   | Name             | Status | Task State | Power State | Networks         |
+--------------------------------------+------------------+--------+------------+-------------+------------------+
| 048054fe-ec19-45ff-a679-83c19ebb5026 | example-instance | ACTIVE | -          | Running     | romana=10.0.17.3 |
+--------------------------------------+------------------+--------+------------+-------------+------------------+

```

A new instance was created, and the IP address `10.0.17.3` was assigned to it. You can SSH into this from the host it was created on.
We can also see from the IP address's network prefix (`10.0/16`) that this instance was created on host `ip-192-168-99-10`. (See the `romana host list` details above.)

```
ubuntu@ip-192-168-99-10:~$ ssh cirros@10.0.17.3
The authenticity of host '10.0.17.3 (10.0.17.3)' can't be established.
RSA key fingerprint is f6:2a:53:3c:e6:62:62:52:6b:17:ba:53:23:1f:c8:3d.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '10.0.17.3' (RSA) to the list of known hosts.
$ 
```

## Details

- See what `iptables` routes were configured: `sudo iptables -nL`
- See routes that were configured: `ip route`
- Log files: these are in `/var/log/upstart/`

## Experiment

Make changes to the setup using the `romana` CLI tool.
- Add new tenants: `romana tenant create <name>` (name should exist in Openstack)
- Add new segments: `romana segment add <tenant-name> <segment-name>

After adding new segments, they can be used when booting new instances via nova.

To experience the segment isolation, create instances inside the same segment and in different segments or even for different tenants.
You will notice that they cannot contact each other, while instances within the same segment can communicate just fine.

Create some instances in `frontend` and `backend segments.
```sh-session
ubuntu@ip-192-168-99-10:~$ nova boot --flavor m1.nano --image cirros-0.3.4-x86_64-uec --key-name shared-key --nic net-id=$(neutron net-show romana -Fid -f value) --meta romanaSegment=frontend fe-1
ubuntu@ip-192-168-99-10:~$ nova boot --flavor m1.nano --image cirros-0.3.4-x86_64-uec --key-name shared-key --nic net-id=$(neutron net-show romana -Fid -f value) --meta romanaSegment=frontend fe-2
ubuntu@ip-192-168-99-10:~$ nova boot --flavor m1.nano --image cirros-0.3.4-x86_64-uec --key-name shared-key --nic net-id=$(neutron net-show romana -Fid -f value) --meta romanaSegment=frontend fe-3
ubuntu@ip-192-168-99-10:~$ nova boot --flavor m1.nano --image cirros-0.3.4-x86_64-uec --key-name shared-key --nic net-id=$(neutron net-show romana -Fid -f value) --meta romanaSegment=frontend fe-4
ubuntu@ip-192-168-99-10:~$ nova boot --flavor m1.nano --image cirros-0.3.4-x86_64-uec --key-name shared-key --nic net-id=$(neutron net-show romana -Fid -f value) --meta romanaSegment=backend be-1
ubuntu@ip-192-168-99-10:~$ nova boot --flavor m1.nano --image cirros-0.3.4-x86_64-uec --key-name shared-key --nic net-id=$(neutron net-show romana -Fid -f value) --meta romanaSegment=backend be-2
ubuntu@ip-192-168-99-10:~$ nova list
+--------------------------------------+------------------+--------+------------+-------------+------------------+
| ID                                   | Name             | Status | Task State | Power State | Networks         |
+--------------------------------------+------------------+--------+------------+-------------+------------------+
| 16af339f-75ad-4729-ad64-c700f10edba9 | be-1             | ACTIVE | -          | Running     | romana=10.0.19.3 |
| 3914c9ea-1ec4-4173-b798-92b4d02ccb88 | be-2             | ACTIVE | -          | Running     | romana=10.0.19.4 |
| 3a21fbec-253f-4e9a-94eb-d81148520bc4 | example-instance | ACTIVE | -          | Running     | romana=10.0.17.3 |
| a4711980-b53c-4b0a-9fdb-e700c96a4d00 | fe-1             | ACTIVE | -          | Running     | romana=10.0.18.3 |
| 0f5fefd2-db80-4661-939e-129b59840581 | fe-2             | ACTIVE | -          | Running     | romana=10.1.18.3 |
| dae5eaa8-e370-413d-88bc-c21bda13aa63 | fe-3             | ACTIVE | -          | Running     | romana=10.0.18.4 |
| 0452b5e0-74e6-4e9f-b02a-f00210ae0ca6 | fe-4             | ACTIVE | -          | Running     | romana=10.0.18.5 |
+--------------------------------------+------------------+--------+------------+-------------+------------------+
```

Now connect to an instance from horizon [no-vnc console](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux_OpenStack_Platform/6/html/Administration_Guide/chap-virtual-machines.html#section-connect-console)
and check that we can reach other VMs within the segment
```sh-session
$ ping 10.0.18.4
PING 10.0.18.4 (10.0.18.4): 56 data bytes
64 bytes from 10.0.18.4: seq=0 ttl=63 time=1393.203 ms
64 bytes from 10.0.18.4: seq=1 ttl=63 time=391.037 ms
64 bytes from 10.0.18.4: seq=2 ttl=63 time=0.857 ms
^C
--- 10.0.18.4 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.857/595.032/1393.203 ms
$ ping 10.0.18.5
PING 10.0.18.5 (10.0.18.5): 56 data bytes
64 bytes from 10.0.18.5: seq=0 ttl=63 time=700.079 ms
64 bytes from 10.0.18.5: seq=1 ttl=63 time=1.018 ms
^C
--- 10.0.18.5 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 1.018/350.548/700.079 ms
$ ping 10.1.18.3
PING 10.1.18.3 (10.1.18.3): 56 data bytes
64 bytes from 10.1.18.3: seq=0 ttl=62 time=7.332 ms
64 bytes from 10.1.18.3: seq=1 ttl=62 time=1.919 ms
^C
--- 10.1.18.3 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max = 1.919/4.625/7.332 ms
$ 
```

Check that we're forbidden from reaching hosts in other segments.
```sh-session
$ ping 10.0.19.4
PING 10.0.19.4 (10.0.19.4): 56 data bytes
^C
--- 10.0.19.4 ping statistics ---
8 packets transmitted, 0 packets received, 100% packet loss
$ ping 10.0.17.3
PING 10.0.17.3 (10.0.17.3): 56 data bytes
^C
--- 10.0.17.3 ping statistics ---
6 packets transmitted, 0 packets received, 100% packet loss
$ 
```

