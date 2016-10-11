# Containerize

![containerize all the things](https://cdn.meme.am/instances/500x/65415534.jpg)

A script to containerize the Romana applications and example Kubernetes Manifest and DaemonSet for installation.

# Requirements

Linux, Docker, internet connection. It was developed on Ubuntu 16.04.

The user running the script should be part of the `docker` group.

# Usage

```bash
# Clone the repository
git clone https://github.com/romana/romana
# Run the script (uses master)
romana/containerize/allthethings
# Build a tagged release
romana/containerize/allthethings --tag=v0.9.3
```

# Installation

## Using kubeadm

Please see the [kubeadm getting started guide](http://kubernetes.io/docs/getting-started-guides/kubeadm/) and complete steps 1, 2, and 3.

Once completed, the following steps will install Romana Services and Romana Agent (CNI).

Download the YAML files.

```bash
files=(
	https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-services-manifest.yml
	https://raw.githubusercontent.com/romana/romana/master/containerize/specs/romana-agent-daemonset.yml
)
wget "${files[@]}"
```

Edit `romana-services-manifest.yml`:
```yaml
  - name: romana-services
    image: quay.io/romana/services
    args:
    # - --cidr=10.0.0.0/8
```

Uncomment the `--cidr` line, and replace the value with an appropriate setting for your environment.

Copy the file into `/etc/kubernetes/manifests` on your master node.

```bash
sudo cp romana-services-manifest.yml /etc/kubernetes/manifests
```

Edit `romana-agent-daemonset.yml`:
```yaml
      - name: romana-agent
        image: quay.io/romana/agent
        args:
        # - --romana-root=http://romana-root:9600
```

Uncomment the `--romana-root` line, and replace with the IP of the node runing romana-services.

Then run:
```bash
kubectl apply -f romana-agent-daemonset.yml
```

Note: The kube-dns component may not operate properly. It can be disabled by runningi `kubectl --namespace=kube-system scale --replicas=0 deployment/kube-dns`

# TODO

* By default, the script will try to push containers to `quay.io/romana`. Disable that with `--push=no`. An option for specifying a different user/org should be added.

