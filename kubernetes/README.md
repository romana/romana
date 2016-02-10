Romana CNI plugin for kubernetes
================================

This CNI plugin demonstrates use of Romana networking with Kubernetes

Romana
------
Is a network orchestration toolchain designed to replace overlay based SDN solutions with good old L3 routing.

CNI
---
[Container networking interface](https://github.com/appc/cni/blob/master/SPEC.md) an interface specification defined as a part of [appc](https://github.com/appc/spec) effor to create network plugins that would work across different container platforms.

Kubernetes
----------
Is a container orchestrating platform that supports CNI interface.

Install
-------
Cloudformation template in this directory will spawn a cluster with Kubernetes and Romana CNI plugin installed. 

For minimum configuration you just need to specify your `KeyName`. 

Default cluster consists of one host that has following services installed.

* kubernetes controller serices
* kubernetes node services
* romana root/topology/tenant/ipam services
* romana agent
* romana CNI plugin

Specifying `AdditionalComputeHosts` parameter during CF startup will result in creation of number of hosts with following services installed.

* kuberentes node services
* romana agent
* romana CNI plugin

What to expect
--------------
* Kubernetes running in multitenant mode with default policy set to prevent cross tenant traffic and to allow any traffic between pods owned by same tenant.
* Kubernetes to recognise Romana annotation for tenants - each pod must specify a label of form `romana.io/tenant=<tenant-id>`. 
* Romana networking configured for 2 tenants, t1 and t2. Example annotation for t1 would be
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
    romana.io/tenant: t1
spec:
  containers:
  - name: nginx
    image: nginx
    ports:
    - containerPort: 80
```
* Romana CNI plugin logs at `/tmp/romana-cni.log`

How to test
-----------
1) Fire up a few pods for same tenant, use `/home/ubuntu/romana/kubernetes/pod.yaml` as an example.
```
root@ip-192-168-0-10:/home/ubuntu# kubectl get pods -o json | jq '.items[] | { podIP: .status.podIP, containerID: .status.containerStatuses[].containerID, Node:.spec.nodeName, Name: .metadata.name }'
{
  "Name": "nginx-t1-1",
  "Node": "i-758563c0",
  "containerID": "docker://ed2cb9af7eaf4bc7baa47e680609aed9b03d2102bba01d729e3da813d59123d3",
  "podIP": "10.3.17.3"
}
{
  "Name": "nginx-t1-2",
  "Node": "i-b6836503",
  "containerID": "docker://2d368f80443ac13d4381f4645e77492118681b3be892945d6e8ad9006cca39bf",
  "podIP": "10.1.17.3"
}
{
  "Name": "nginx-t1-3",
  "Node": "i-0f8563ba",
  "containerID": "docker://41cb36dbb994c6549574582bca49d2855aa6807116715adeeb8e911df1f07d78",
  "podIP": "10.0.17.3"
```
2) Enter one pod namespace. It is easier with pods located on master node.
```
root@ip-192-168-0-10:/home/ubuntu# CID=$(kubectl get pods nginx-t1-3 -o json | jq -r '.status.containerStatuses[].containerID')
root@ip-192-168-0-10:/home/ubuntu# PID=$(docker top ${CID##docker://} | tail -n1 | awk '{ print $2 }')
root@ip-192-168-0-10:/home/ubuntu# nsenter -t $PID -n
root@ip-192-168-0-10:/home/ubuntu# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
9: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether ae:b6:82:61:c7:ae brd ff:ff:ff:ff:ff:ff
    inet 10.0.17.3/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::acb6:82ff:fe61:c7ae/64 scope link 
       valid_lft forever preferred_lft forever
```
3) Ping/Curl any other pod
```
root@ip-192-168-0-10:/home/ubuntu# ping 10.3.17.3
PING 10.3.17.3 (10.3.17.3) 56(84) bytes of data.
64 bytes from 10.3.17.3: icmp_seq=1 ttl=62 time=385 ms
64 bytes from 10.3.17.3: icmp_seq=2 ttl=62 time=0.601 ms
^C
--- 10.3.17.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1000ms
rtt min/avg/max/mdev = 0.601/193.104/385.608/192.504 ms
```
4) Create pod for tenant t2 and try to ping across tenants

NetworkPolicy
-------------

Kubernetes 3rd party resource is running on kubernetes master node allowing to manage
NetworkPolicy objects.

```
# create
curl -X POST -d @romana-network-policy-request2.json http://localhost:8080/apis/romana.io/demo/v1/namespaces/default/networkpolicys/
```
