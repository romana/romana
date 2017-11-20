# Romana DNS

Romana DNS adds DNS support for Romana VIPs. It is drop in replacement for
kube-dns.

## Installtion steps

### On Master node of kubernetes cluster

* Make a note on number of replicas for kube-dns using following command:
```
echo `kubectl get deploy -n kube-system kube-dns -o jsonpath="{.spec.replicas}"`
``` 
* Now set replicas for kube-dns to zero using following command:
```
kubectl scale deploy -n kube-system kube-dns --replicas=0
```
* Wait till kube-dns replicas are zero (around a minute or so)

### On All nodes i.e master and compute nodes of the kubernetes cluster

* Remove earlier docker images and replace it romana one using commands below:
```
docker rmi gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.5
docker pull pani/romanadns
docker tag pani/romanadns:latest gcr.io/google_containers/k8s-dns-kube-dns-amd64:1.14.5
```
* Now return back to master node for further commands

### On Master node of kubernetes cluster

* Now assuming you had 2 replicas before, from first step above, we restore the replica count for kube-dns as follows:
```
kubectl scale deploy -n kube-system kube-dns --replicas=2
```
* Wait for a minute or so for the pod to come up and we have romanaDNS up and running.

## Testing

* Run dig to see if dns is working properly using command:
```
dig @10.96.0.10 +short romana.kube-system.svc.cluster.local
```
* Download this sample [nginx](files/nginx.yml) yaml file and then use following command to create an nginx service with RomanaIP in it:
```
kubectl create -f nginx.yml
```
* This should create and load nginx service with RomanaIP, which should reflect in the dig result below:
```
dig @10.96.0.10 +short nginx.default.svc.cluster.local
```

### Sample Results
```
$ dig @10.96.0.10 +short romana.kube-system.svc.cluster.local
10.96.0.99
192.168.99.10
$ dig @10.96.0.10 +short nginx.default.svc.cluster.local
10.116.0.0
10.99.181.64
192.168.99.101
```

***
