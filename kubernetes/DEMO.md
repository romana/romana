This is a script for kubernetes demo
====================================

Start example replication controller
```
root@ip-192-168-0-10:/home/ubuntu# kubectl create -f romana/kubernetes/example-conroller.yaml 
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
root@ip-192-168-0-10:/home/ubuntu# kubectl get pods -o wide
NAME                  READY     STATUS    RESTARTS   AGE       NODE
nginx-backend         1/1       Running   0          3m        i-b53ce076
nginx-default-671ns   1/1       Running   0          5m        i-b53ce076
nginx-default-l3m3i   1/1       Running   0          5m        i-d73ce014
nginx-default-wid28   1/1       Running   0          5m        i-d73ce014
nginx-frontend        1/1       Running   0          3m        i-d73ce014
```

Pick one of nginx-default- container that is running in master node and step into it
```
root@ip-192-168-0-10:/home/ubuntu# ./romana/kubernetes/step-into.sh nginx-default-wid28
Stepping into container docker://e0f2cd8e7f0242dcc596f8d1bb32ebb10da4be2a141d94e585651a7f6dbc4d10 namespace
```

Verify that we are in containers network namespace
```
root@ip-192-168-0-10:/home/ubuntu# ip a show eth0
25: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether b6:e6:0b:4d:8d:5c brd ff:ff:ff:ff:ff:ff
    inet 10.0.33.11/16 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::b4e6:bff:fe4d:8d5c/64 scope link 
       valid_lft forever preferred_lft forever
```

Verify access to other containers owner by same tenant and located in same segment
```
root@ip-192-168-0-10:/home/ubuntu# curl 10.0.33.9
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
```

Verify that access between nginx-backend and nginx-frontend is blocked by stepping in nginx-frontend (might need to ssh into kube node that hosts is first ) namespace and trying to access nginx-backend
```
root@ip-192-168-0-10:/home/ubuntu# ./romana/kubernetes/step-into.sh nginx-frontend
Stepping into container docker://ab1af51403e710e215f049776d57f8ffdfd58ff9ce4e6d47795e0977d9596264 namespace
root@ip-192-168-0-10:/home/ubuntu# curl 10.1.19.3
^C
```

Create network policy object to allow access from nginx-frontend to nginx-backend
```
curl -X POST -d @romana/kubernetes/romana-network-policy-request.json http://localhost:8080/apis/romana.io/demo/v1/namespaces/default/networkpolicys/
```

Verify that access from nginx-frontend to nginx-backend now allowed
```
root@ip-192-168-0-10:/home/ubuntu# ./romana/kubernetes/step-into.sh nginx-frontend
Stepping into container docker://ab1af51403e710e215f049776d57f8ffdfd58ff9ce4e6d47795e0977d9596264 namespace
root@ip-192-168-0-10:/home/ubuntu# curl 10.1.19.3
^C
```
