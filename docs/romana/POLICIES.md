# Romana network policies

## Introduction

Romana allows the fine grained control and management of network traffic via network policies. The Romana network policies format was inspired by the Kubernetes network policy specification. However, Romana policies can be applied in Kubernetes as well as OpenStack environments. Furthermore, Romana extends the policies with additional features, such as the ability to control network traffic not only for containers or VMs, but also for bare metal servers.

### Overview

Network policies are defined as small JSON snippets, specifying match characteristics for network traffic. Essentially, network policies firewall rules definitions. Details and examples will be given below.

These policy definitions are sent to the Romana Policy service using this service's RESTful API. The service validates those policies and forwards them to the Romana agent on each host of the cluster. There, the policies are translated to iptables rules, which are then applied to the kernel. 

### Tools and integration

After installing an OpenStack or Kubernetes cluster with Romana, the `romana` command line tool can be used to specify and list policies. However, Romana provides a specific integration for Kubernetes. This allows the operator to use standard Kubernetes policies and policy APIs, should they wish to do so. Romana picks up those Kubernetes policies, seamlessly translates them to Romana policies and then applies them as necessary.

For OpenStack, or if policies need to be applied to bare metal servers, the Romana Policy API or command line tools are used directly.


## Policy definition format

Each Romana network policy document contains a single top-level element (`securitypolicies`), which itself is a list of individual policies. A policy contains the following top-level elements:

* **name:** The name of the policy. You can refer to policies by name or an automatically generated unique ID. Oftentimes names are much easier to remember. Therefore, it is useful to make this a short, descriptive and - if possible - unique ID.
* **description:** A line of text, which can serve as human readable documentation for this policy.
* **direction:** Determines whether the policy applies packets that are incoming (ingress) to the endpoint or outgoing (egress) from the endpoint. Currently, the only permissible value for this field is `ingress`. This means that the policy rules describe traffic travelling TO the specified (see `applied_to`) target.
* **applied_to:** A list of specifiers, defining to whom the rules are applied. Typically a tenant/segment combo or a CIDR.
* **peers:** A list of specifiers, defining the 'other side' of the traffic. In case of ingress traffic, this would be the originator of the packets. The peer may be defined as "any", which serves as a wildcard.
* **rules:** A list of traffic type specifications, usually consisting of protocol and ports.


```
{
    "securitypolicies": [{
        "name":        <policy-name>,
        "description": <policy-description>,
        "direction":   "ingress",
        "applied_to":  [<applied-spec-1>, <applied-spec-2>, ...],
        "peers":       [<peer-spec-1>, <peer-spec-2>, ...],
        "rules":       [<traffic-spec-1>, <traffic-spec-2>, ...]
    }]
}
```
Example:
```
{
    "securitypolicies": [{
        "name": "policy1",
        "description": "Opening SSH, HTTP and HTTPS ports as well as ICMP",
        "direction": "ingress",
        "applied_to": [{
            "tenant": "admin",
            "segment": "default"
        }],
        "peers": [{
            "peer": "any"
        }],
        "rules": [
            {
                "protocol": "tcp",
                "ports": [22, 80, 443]
            },
            {
                "protocol": "icmp"
            }
        ]
    }]
}
```

***

