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

## Romana Services

Edit the file: `romana/containerize/specs/romana-services.manifest`:
```yaml
  - name: romana-services
    image: quay.io/romana/services
    args:
    # - --cidr=10.0.0.0/8
    # - --api-server=http://kube-apiserver:8080
```
Uncomment the two lines, and replace with the appropriate values for your environment.
Copy the file into `/etc/kubernetes/manifests` on your master node.



## Romana Agent

Edit the file: `romana/containerize/specs/romana-agent-daemonset.yml`:
```yaml
      - name: romana-agent
        image: quay.io/romana/agent
        args:
        # - --api-server=http://kube-apiserver:8080
        # - --romana-root=http://romana-root:9600
```
Uncomment the two lines, and replace with the appropriate values for your environment.
Then run:
```bash
kubectl create -f romana-agent-daemonset.yml`
```

# TODO

* By default, the script will try to push containers to `quay.io/romana`. Disable that with `--push=no`. An option for specifying a different user/org should be added.

