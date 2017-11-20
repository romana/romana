# Romana Route Publisher Add-On

For Kubernetes clusters installed in datacenters, it is useful to enable the
Romana Route Publisher add-on.  It is used to automatically announce routes for
Romana addresses to your BGP- or OSPF-enabled router, removing the need to
configure these manually.

Because the routes are for prefixes instead of precise /32 endpoint addresses,
the rate and volume of routes to publish is reduced.

## Configuration

The Romana Route Publisher uses [BIRD](http://bird.network.cz/) to announce
routes from the node to other network elements.  Configuration is separated
into two parts:

- a static `bird.conf` to describe the basic configuration of BIRD, ending with an `include`
- a dynamic `publisher.conf` that is used to generate a config containing routes for Romana addresses

When the pod first launches, BIRD is launched using the static configuration.
Then, when new blocks of Romana addreses are allocated to a node, the dynamic
configuration is generated with routes for those blocks, and BIRD is given a
signal to reload its configuration.

If your configuration requires custom configuration per-node or per-subnet,
there is a naming convention for the files that can be used to support this.

Both config files will look for a "best match" extension to the name first.
When loading `x.conf` on a node with IP `192.168.20.30/24`, it will first look
for:

- `x.conf.192.168.20.30` (IP suffix for node-specific config)
- `x.conf.192.168.20.0`  (Network address suffix, for subnet-specific config)
- `x.conf`

## Examples

### bird.conf (for both BGP and OSPF)

    router id from 192.168.0.0/16;

    protocol kernel {
        scan time 60;
        import none;
            export all;
    }

    protocol device {
        scan time 60;
    }

    include "conf.d/*.conf";

- Make sure the CIDR specified for `router id` matches your cluster nodes.
- The `protocol kernel` and `protocol device` can be modified, or just deleted if not necessary.
- Add any additional, global BIRD configuration to this file (eg: debugging, timeouts, etc)
- The `include` line is the hook to load the generated dynamic config. It should be in your `bird.conf` exactly as specified.

### publisher.conf for OSPF

    protocol static romana_routes {
        {{range .Networks}}
        route {{.}} reject;
        {{end}}
    }

    protocol ospf OSPF {
      export where proto = "romana_routes";
      area 0.0.0.0 {
        interface "eth0" {
          type broadcast;
        };
      };
    }

- The first section, `protocol static static_bgp` is used by the `romana-route-publisher` to generate a dynamic config.
- The second section, `protocol ospf OSPF` should contain the `export` entry, and `area` blocks to match your environment.
- The interface names will need to be modified to match the node's actual interfaces
- Add any additional, protocol-specific BIRD configuration to this file

### publisher.conf for BGP

    protocol static romana_routes {
        {{range .Networks}}
        route {{.}} reject;
        {{end}}
    }

    protocol bgp BGP {
        export where proto = "romana_routes";
            direct;
        local as {{.LocalAS}};
        neighbor 192.168.20.1 as {{.LocalAS}};
    }

- The first section, `protocol static static_bgp` is used by the `romana-route-publisher` to generate a dynamic config.
- The second section, `protocol bgp BGP` should be changed to match your specific BGP configuration.
- Add any additional, protocol-specific BIRD configuration to this file
- The `neighbor` address will likely be different for each subnet. To handle this, you can use multiple `publisher.conf` files with the appropriate network address suffixes, eg:
  - bird.conf.192.168.20.0
  - bird.conf.192.168.35.0

## Installation

First, the configuration files need to be loaded into a `configmap`.

1) Put all the files into a single directory
2) `cd` to that directory
3) Run `kubectl -n kube-system create configmap route-publisher-config --from-file=.` (the `.` indicates the current directory)

Next, download the YAML file from
[here](https://raw.githubusercontent.com/romana/romana/romana-2.0/docs/kubernetes/specs/romana-route-publisher.yaml)
to your master node.

Then, load the Romana Route Publisher add-on by running this command on your master node.

    kubectl apply -f romana-route-publisher.yaml

## Verification

Check that route publisher pods are running correctly

    $ kubectl -n kube-system get pods --selector=romana-app=route-publisher
    NAME                           READY     STATUS    RESTARTS   AGE
    romana-route-publisher-22rjh   2/2       Running   0          1d
    romana-route-publisher-x5f9g   2/2       Running   0          1d

Check the logs of the bird container inside the pods

    $ kubectl -n kube-system logs romana-route-publisher-22rjh bird
    Launching BIRD
    bird: Chosen router ID 192.168.XX.YY according to interface XXXX
    bird: Started

Other messages you may see in this container:

    bird: Reconfiguration requested by SIGHUP
    bird: Reconfiguring
    bird: Adding protocol romana_routes
    bird: Adding protocol OSPF
    bird: Reconfigured

Check the logs of the publisher container inside the pods

    $ kubectl -n kube-system logs romana-route-publisher-22rjh publisher
    Checking if etcd is running...ok.
    member 8e9e05c52164694d is healthy: got healthy result from http://10.96.0.88:12379
    cluster is healthy
    Checking if romana daemon is running...ok.
    Checking if romana networks are configured...ok. one network configured.
    Checking for route publisher template....ok
    Checking for pidfile from bird...ok
    Launching Romana Route Publisher

Other messages you may see in this container:

    20XX/YY/ZZ HH:MM:SS Starting bgp update at 65534 -> : with 2 networks
    20XX/YY/ZZ HH:MM:SS Finished bgp update

These are normal, even if OSPF is being used.

***
