# Using Romana on Devstack

When installation completes, some SSH commands are provided for logging into your new hosts, eg:
```bash
ssh -i /.../romana-install/romana_id_rsa ubuntu@52.xx.yy.zz
ssh -i /.../romana/romana-install/romana_id_rsa ubuntu@54.zz.yy.xx
```

These can be used to log into the host using the generated SSH key. Use the SSH command for the controller to log in.

## Look up information

A `romana` tool has been provided that lets you see details about the setup, and make changes.
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
By default, we have two hosts (`192.168.99.10` and `192.168.99.11`). Each host has its own CIDR (`10.0.0.1/16`, `10.1.0.1/16`) that it will use when allocating IP addresses.

```sh-session
ubuntu@ip-192-168-99-10:~$ romana show-tenants
Listing 2 tenant(s)
c858ac6ab9534f8f86f2fe9a731277e1 (admin)
7b593643644243e48915acd98df7b0d0 (demo)
ubuntu@ip-192-168-99-10:~$ romana show-tenant admin
Tenant:c858ac6ab9534f8f86f2fe9a731277e1 (admin)
Segments: default, s1, s2
```

We've also created `admin` and `demo` tenants, with segments. If the `admin` user creates a new instance, it needs to provide a named segment.
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

A new instance was created, and has IP `10.0.17.3`. You can SSH into this from the host it was created on.

```
ubuntu@ip-192-168-99-10:~$ ssh cirros@10.0.17.3
The authenticity of host '10.0.17.3 (10.0.17.3)' can't be established.
RSA key fingerprint is f6:2a:53:3c:e6:62:62:52:6b:17:ba:53:23:1f:c8:3d.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '10.0.17.3' (RSA) to the list of known hosts.
$ 
```

## Details

- See what `iptables` were configured: `sudo iptables -nL`
- Log files: these are in `/var/log/upstart/`

## Experiment

Make changes to the setup using the `romana` CLI tool.
- Add new hosts: `romana add-host <hostname> <host-ip> <romana-cidr> <agent-port>`
- Add new tenants: `romana create-tenant <name>` (name should exist in Openstack)
- Add new segments: `romana add-segment <tenant-name> <segment-name>

After creating things, they should be immediately available for use when creating new instances.

To experience the segment isolation, create instances inside the same segment and in different tenants.
Then, log into one of them and see what other instances are reachable.
