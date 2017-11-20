# Introduction

Romana uses an advanced, _topology aware IPAM_ module in order to assign IP
addresses to endpoints (pods or VMs). The topology awareness of Romana's IPAM
allows for the endpoint IPs to align with the topology of your network. This in
turn makes it possible for Romana to effectively aggregate routes. This has
many operational and security advantages:

* Ability to use native L3 routing, allowing network equipment to work at its best
* Greatly reduced number of routes in your networking hardware
* Stable routing configurations, less route updates required
* No "leaking" of endpoint routes into the networking fabric

Key to Romana's topology aware IPAM is the _topology configuration_. In this
configuration you model the underlying network topology for your cluster.

## Terminology

Some useful terminology:

* **Network**: Romana's IPAM chooses endpoint IP addresses from one or more
  address ranges (CIDRs). Each of those is called a "network" in the Romana
  topology configuration. 
* **Address block**: Romana manages IP addresses in small blocks. Usually these
  blocks may contain 8, 16 or 32 addresses. If an IP address is needed on a host,
  Romana assigns one of those blocks there, then uses up the block addresses for
  any further endpoints on the host before assigning a new block. Block sizes are
  specified as network mask lengths, such as "29" (which would mean a `/29` CIDR
  for the block). You see this parameter in the topology configuration. It
  effects some networking internals, such as the number of routes created on
  hosts or ToRs. For the most part you don't need to worry about it and can just
  leave it at "29".
* **Tenant**: This may be an OpenStack tenant, or a Kubernetes namespace.
* **Group**: This is a key concept of Romana's IPAM. All hosts within a group
  will use endpoint addresses that share the same network prefix. That's why
  Romana's "groups" are also called "prefix groups". This is an important
  consideration for topology aware addressing and route aggregation.
* **Prefix group**: See "group".

## Examples

To make it easy for you to get started we have put together this page with
examples for common configurations. The configurations are specified in JSON.
To explain individual lines, we have added occasional comments (starting with
'#'). Since JSON does not natively support comments, you would need to strip
out those before using any of these sample config files.

We have the following examples:

* [Single flat network](#single-flat-network)
* [Single, flat network with host-specific prefixes](#single-flat-network-with-host-specific-prefixes)
* [Using multiple networks](#using-multiple-networks)
* [Using multiple topologies](#using-multiple-topologies)
* [Restricting tenants to networks](#restricting-tenants-to-networks)
* [Deployment in a multi-rack data center](#deployment-in-a-multi-rack-data-center)
* [Deployment in a multi-zone, multi-rack data center](#deployment-in-a-multi-zone-multi-rack-data-center)

### Single, flat network

Use this configuration if you have hosts on a single network segment: All hosts can reach each other directly, no router is needed to forward packets. Another example may be hosts in a single AWS subnet.

Note that in the configuration we usually don't list the actual hosts. As nodes/hosts are added to a cluster, Romana selects the 'group' to which the host will be assigned automatically.

    {
        "networks": [                           # 'networks' or CIDRs from which Romana chooses endpoint addresses
            {
                "name"      : "my-network",     # each network needs a unique name...
                "cidr"      : "10.111.0.0/16",  # ... and a CIDR.
                "block_mask": 29                # size of address blocks for this network, safe to leave at "/29"                                
            }
        ],
        "topologies": [                         # list of topologies Romana knows about, just need one here
            {
                "networks": [                   # specify the networks to which this topology applies
                    "my-network"
                ],
                "map": [                        # model the network's prefix groups
                    {                           # if only one group is specified, it will use entire network CIDR
                        "groups": []            # just one group, all hosts will be added here
                    }
                ]
            }
        ]
    }

### Single, flat network with host-specific prefixes

Same as above, but this time we want each host to have its own 'prefix group': All endpoints on a host should share the same prefix. This is useful if you wish to manually set routes in other parts of the network, so that traffic to pods can be delivered to the correct host.

Note that Romana automatically calculates prefixes for each prefix group: The available overall address space is carved up based on the number of groups. The example below shows this in the comments.

When a host is added to a cluster, Romana assigns hosts to (prefix) groups in a round-robin sort of fashion. Therefore, if the number of defined groups is at least as high as the number of hosts in your cluster, each host will live in its own prefix group.

    {
        "networks": [
            {
                "name"      : "my-network",
                "cidr"      : "10.111.0.0/16",
                "block_mask": 29                
            }
        ],
        "topologies": [
            {
                "networks": [ "my-network" ],
                "map": [                         # add at least as many groups as you will have hosts
                    { "groups": [] },            # endpoints get addresses from 10.111.0.0/18
                    { "groups": [] },            # endpoints get addresses from 10.111.64.0/18
                    { "groups": [] },            # endpoints get addresses from 10.111.128.0/18
                    { "groups": [] }             # endpoints get addresses from 10.111.192.0/18
                ]
            }
        ]
    }

### Using multiple networks

Sometimes you may have multiple, smaller address ranges available for your pod or VM addresses. Romana can seamlessly use all of them. We show this using the single, flat network topology from the first example.

    {
        "networks": [
            {
                "name"      : "net-1",
                "cidr"      : "10.111.0.0/16",
                "block_mask": 29                
            },
            {
                "name"      : "net-2",              # unique names for each network
                "cidr"      : "192.168.3.0/24",     # can be non-contiguous CIDR ranges
                "block_mask": 31                    # each network can have different block size
            }
        ],
        "topologies": [
            {
                "networks": [ "net-1", "net-2" ],   # list all networks that apply to the topology
                "map": [
                    { "groups": [] }                # endpoints get addresses from both networks 
                ]
            }
        ]
    }

### Using multiple topologies

It is possible to define multiple topologies, which are handled by Romana at the same time. The following example shows this. We have a total of three networks. One topology (all hosts in the same prefix group) is used for two of the networks. A third network is used by a topology, which gives each host its own prefix group (assuming the cluster does not have more than four nodes).

    {
        "networks": [
            {
                "name"      : "net-1",
                "cidr"      : "10.111.0.0/16",
                "block_mask": 29                
            },
            {
                "name"      : "net-2",
                "cidr"      : "10.222.0.0/16",
                "block_mask": 28
            },
            {
                "name"      : "net-3",
                "cidr"      : "172.16.0.0/16",
                "block_mask": 30
            }
        ],
        "topologies": [
            {
                "networks": [ "net-1", "net-2" ],
                "map": [
                    { "groups": [] }                # endpoints get addresses from 10.111.0.0/16 and 10.222.0.0/16
                ]
            },
            {
                "networks": [ "net-3" ],
                "map": [
                    { "groups": [] },               # endpoints get addresses from 172.16.0.0/18
                    { "groups": [] },               # endpoints get addresses from 172.16.64.0/18
                    { "groups": [] },               # endpoints get addresses from 172.16.128.0/18
                    { "groups": [] }                # endpoints get addresses from 172.16.192.0/18
                ]
            }
        ]
    }

### Restricting tenants to networks

Romana can ensure that tenants are given addresses from specific address ranges. This allows separation of traffic in the network, using traditional CIDR based filtering and security policies.

This is accomplished via a new element: A `tenants` spec can be provided with each network definition.

Note that Romana does NOT influence the placement of new pods/VMs. This is done by the environment (Kubernetes or OpenStack) independently of Romana. Therefore, unless you have specified particular tenant-specific placement options in the environment, it is usually a good idea to re-use the same topology - or at least use a topology for all cluster hosts - for each tenant.

    {
        "networks": [
            {
                "name"      : "production",
                "cidr"      : "10.111.0.0/16",
                "block_mask": 29,
                "tenants"   : [ "web", "app", "db" ]
            },
            {
                "name"      : "test",
                "cidr"      : "10.222.0.0/16",
                "block_mask": 32,
                "tenants"   : [ "qa", "integration" ]
            }
        ],
        "topologies": [
            {
                "networks": [ "production", "test" ],
                "map": [
                    { "groups": [] } 
                ]
            }
        ]
    }

### Deployment in a multi-rack data center

The topology file is used to model your network. Let's say you wish to deploy a cluster across four racks in your data center. Let's assume each rack has a ToR and that ToRs can communicate with each other. Under each ToR (in each rack) there are multiple hosts.

As nodes/hosts are added to your cluster, you should provide labels in the meta data of each host, which can assist Romana in placing the host in the correct, rack-specific prefix group. Both Kubernetes and OpenStack allow you to define labels for nodes. You can choose whatever label names and values you wish, just make sure they express the rack of the host and are identical in the environment (Kubernetes or OpenStack) as well as in the Romana topology configuration.

In this example, we use `rack` as the label. We introduce a new element to the Romana topology configuration: The `assignment` spec, which can be part of each group definition.

Note that such a multi-rack deployment would usually also involve the installation of the _Romana route publisher_, so that ToRs can be configured with the block routes to the hosts in the rack.

    {
        "networks": [
            {
                "name"      : "my-network",
                "cidr"      : "10.111.0.0/16",
                "block_mask": 29                
            }
        ],
        "topologies": [
            {
                "networks": [ "my-network" ],
                "map": [
                    {
                        "assignment": { "rack": "rack-1" },   # all nodes with label 'rack == rack-1'...
                        "groups"    : []                      # ... are assigned by Romana to this group
                    },
                    {
                        "assignment": { "rack": "rack-2" },
                        "groups"    : []
                    },
                    {
                        "assignment": { "rack": "rack-3" },
                        "groups"    : []
                    },
                    {
                        "assignment": { "rack": "rack-4" },
                        "groups"    : []
                    },
                ]
            }
        ]
    }

### Deployment in a multi-zone, multi-rack data center

Larger clusters may be spread over multiple data centers, or multiple spines in the data center. Romana can manage multi-hierarchy prefix groups, so that the routes across the DCs or spines can be aggregated into a single route.

The following example shows a cluster deployed across two "zones" (DCs or spines), with four racks in one zone and two racks in the other. We use multiple labels ("zone" in addition to "rack") in order to assign nodes to prefix groups.

    {
        "networks": [
            {
                "name"      : "my-network",
                "cidr"      : "10.111.0.0/16",
                "block_mask": 29                
            }
        ],
        "topologies": [
            {
                "networks": [ "my-network" ],
                "map": [
                    {
                        "assignment": { "zone" : "zone-A" },
                        "groups"    : [                              # addresses from 10.111.0.0/17
                            {
                                "assignment": { "rack": "rack-3" },
                                "groups"    : []                     # addresses from 10.111.0.0/19
                            },
                            {
                                "assignment": { "rack": "rack-4" },
                                "groups"    : []                     # addresses from 10.111.32.0/19
                            },
                            {
                                "assignment": { "rack": "rack-7" },
                                "groups"    : []                     # addresses from 10.111.64.0/19
                            },
                            {
                                "assignment": { "rack": "rack-9" },
                                "groups"    : []                     # addresses from 10.111.96.0/19
                            }
                        ]
                    },
                    {
                        "assignment": { "zone" : "zone-B" },
                        "groups"    : [                              # addresses from 10.111.128.0/17
                            {
                                "assignment": { "rack": "rack-17" },
                                "groups"    : []                     # addresses from 10.111.128.0/18
                            },
                            {
                                "assignment": { "rack": "rack-22" },
                                "groups"    : []                     # addresses from 10.111.192.0/18
                            }
                        ]
                    }
                ]
            }
        ]
    }

***

