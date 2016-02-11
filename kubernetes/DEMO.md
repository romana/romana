Key restrictions at this time
=============================
* K8S doesn’t support tenants, so we emulate tenancy by adding meta data and labels, such as what you see in the polocy.
* Only use policies of exactly the defined nature and template. We can currently only handle TCP and port. No other protocols.
* Even though “from” and “toPorts” are list items, we currently only support exactly one item for each of those.
* The policy name cannot be more than 6 characters long!
* Do not apply/edit/delete policies BEFORE you create the pods, ONLY AFTER the pods are up and running. This will eventually be allowed, but for now it is not.
* What is the meaning of “tier” and “owner” and where does “frontend” and “backend” come from (all of those are used in the policy)? To make the policy nicer to look at for the demo we decided to use “tier” instead of “romana.io/segment”. We hard-coded that into our code for now! Same with “owner” being easier to look at than “romana.io/tenant”. For ‘owner’ you can see that we used ‘t1’, which happens to be the name of a pre-created tenant in the Romana system. To make the policy nicer looking for the demo, we also pre-created segments with the names “frontend” and “backend”, rather than the usual “s1”, “s2”, etc. That’s also currently hard-coded in our setup. Clearly, more flexibility around this will be provided for production. So, now you know where those names came from and how they map to Romana.
* Policies are applied to segments, not individual pods.
* By default, Romana will allow all pods within the same “tier” (segment) to talk to each other.
* Names of “tiers” (segments) don’t have to be unique across the system, they just need to be unique within a tenant.


This is a script for kubernetes demo
====================================

Start example replication controller
```
root@ip-192-168-0-10:/home/ubuntu# kubectl create -f romana/kubernetes/example-controller.yaml
replicationcontroller "nginx-default" created
```
**This controller would start 3 pods for tenant `t2` in segment `default`, communication between this pods should be allowed by deafult policy**

Start example pods for another tenant
```
root@ip-192-168-0-10:/home/ubuntu# kubectl create -f romana/kubernetes/pod-frontend.yaml 
pod "nginx-frontend" created
```
**This pod is started for tenant `t2` in segment `frontend`, default policy should block communication with other tenants and segments**

```
root@ip-192-168-0-10:/home/ubuntu# kubectl create -f romana/kubernetes/pod-backend.yaml 
pod "nginx-backend" created
```
**This pod is started for tenant `t2` in segment `backend`, default policy should block communication with other tenants and segments, even with `nginx-frontend`**


Verify containers started
```
root@ip-192-168-0-10:/home/ubuntu# kubectl get pods -o json | jq '.items[] | { Name: .metadata.name, podIP: .status.podIP, NodeID: .spec.nodeName, Status: .status.phase }'
{
  "Status": "Running",
  "NodeID": "i-d820c06d",
  "podIP": "10.0.19.3",
  "Name": "nginx-backend"
}
{
  "Status": "Running",
  "NodeID": "i-d820c06d",
  "podIP": "10.0.33.3",
  "Name": "nginx-default-vnri5"
}
{
  "Status": "Running",
  "NodeID": "i-6e20c0db",
  "podIP": "10.1.33.3",
  "Name": "nginx-default-yb1rp"
}
{
  "Status": "Running",
  "NodeID": "i-6e20c0db",
  "podIP": "10.1.33.5",
  "Name": "nginx-default-yc4sy"
}
{
  "Status": "Running",
  "NodeID": "i-d820c06d",
  "podIP": "10.0.18.3",
  "Name": "nginx-frontend"
}
```

Pick one of nginx-default- container that is running in master node and step into it. The "step-into" script merely puts you into the namespace of the specified container, as if you had logged into it.
```
root@ip-192-168-0-10:/home/ubuntu# ./romana/kubernetes/step-into.sh nginx-default-wid28
Stepping into container docker://e0f2cd8e7f0242dcc596f8d1bb32ebb10da4be2a141d94e585651a7f6dbc4d10 namespace
```

Verify that we are in containers network namespace
```
root@ip-192-168-0-10:/home/ubuntu# ip a show eth0
9: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 86:28:84:d9:a0:f6 brd ff:ff:ff:ff:ff:ff
    inet 10.0.33.3/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::8428:84ff:fed9:a0f6/64 scope link 
       valid_lft forever preferred_lft forever
```

Verify access to other containers owner by same tenant and located in same segment
```
root@ip-192-168-0-10:/home/ubuntu# curl 10.1.33.5
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

Verify that access to other tenants/segments is blocked by accessing nginx-frontend container
```
root@ip-192-168-0-10:/home/ubuntu# curl 10.0.18.3
^C
root@ip-192-168-0-10:/home/ubuntu# exit
logout
```

Verify that access between nginx-backend and nginx-frontend is blocked by stepping in nginx-frontend (might need to ssh into kube node that hosts is first ) namespace and trying to access nginx-backend
```
root@ip-192-168-0-10:/home/ubuntu# ./romana/kubernetes/step-into.sh nginx-frontend
Stepping into container docker://311bbe131631074bd9080a214cc7582f2ad79600626919345f32e19cdb82b577 namespace
root@ip-192-168-0-10:/home/ubuntu# curl 10.0.19.3
^C
root@ip-192-168-0-10:/home/ubuntu# exit
logout
```

Create network policy object to allow access from nginx-frontend to nginx-backend
```
root@ip-192-168-0-10:/home/ubuntu# curl -X POST -d @romana/kubernetes/romana-network-policy-request.json http://localhost:8080/apis/romana.io/demo/v1/namespaces/default/networkpolicys/
{
  "apiVersion": "romana.io/demo/v1",
  "kind": "NetworkPolicy",
  "metadata": {
    "name": "policy1",
    "namespace": "default",
    "selfLink": "/apis/romana.io/demo/v1/namespaces/default/networkpolicys/policy1",
    "uid": "262fd5e3-d109-11e5-8078-06f9d64b8ea3",
    "resourceVersion": "307",
    "creationTimestamp": "2016-02-11T21:48:13Z",
    "labels": {
      "owner": "t1"
    }
  },
  "spec": {
    "allowIncoming": {
      "from": [
        {
          "pods": {
            "tier": "frontend"
          }
        }
      ],
      "toPorts": [
        {
          "port": 80,
          "protocol": "TCP"
        }
      ]
    },
    "podSelector": {
      "tier": "backend"
    }
  }
}
```

Verify that access from nginx-frontend to nginx-backend now allowed
```
root@ip-192-168-0-10:/home/ubuntu# ./romana/kubernetes/step-into.sh nginx-frontend
Stepping into container docker://311bbe131631074bd9080a214cc7582f2ad79600626919345f32e19cdb82b577 namespace
root@ip-192-168-0-10:/home/ubuntu# curl 10.0.19.3
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
