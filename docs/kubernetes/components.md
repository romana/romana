# Romana on Kubernetes - Components

An installation of Romana on Kubernetes has a number of essential components, and some add-on components for specific cloud providers. These are currently available for AWS, and components for other cloud providers will be developed in the future.

- Essential Components
  * [romana-etcd](#romana-etcd)
  * [romana-daemon](#romana-daemon)
  * [romana-listener](#romana-listener)
  * [romana-agent](#romana-agent)
- Add-on Components for AWS
  * [romana-aws](#romana-aws)
  * [romana-vpcrouter](#romana-vpcrouter)

Details of each component and example YAML configurations are provided below.

## Essential Components

### romana-etcd

A Romana installation requires access to `etcd` for storing information about hosts, routing, IP addresses and other essential configuration and state.
This can be the same etcd storage used by Kubernetes itself, dedicated etcd storage for Romana, or a standalone pod.

#### Expose Kubernetes etcd

If you are using the Kubernetes etcd storage for Romana, then it is exposed as a service. See the example [etcd-service](specs/etcd-service.yaml) YAML file.
To match this with a custom environment, you need to ensure
* The `clusterIP` is specified and a valid value for your cluster's `--service-cluster-ip-range`. The value for this range can be found in the configuration for your `kube-apiserver`.
* The `targetPort` must match the port used by clients to connect to etcd. You will find this value in the environment variable `ETCD_LISTEN_CLIENT_URLS` or the command-line option `--listen-client-urls` for etcd.
* The `selector` lists labels that must match your etcd pods. Please ensure your etcd pods have a distinct label and that the `selector` matches that label.

#### Dedicated etcd storage

You can deploy your own etcd instance or cluster within Kubernetes and make Romana use that instead of the Kubernetes etcd.
It's highly recommended to expose that dedicated etcd storage as a service. See the section above for details.

#### Standalone pod

In simplified environments with a single master node, for demonstration or experimentation, you can create a standalone etcd instance for Romana to use. See the example [etcd-standalone](specs/etcd-standalone.yaml) YAML file.
This is not recommended for production purposes because it is not fault-tolerant - losing the master node means losing critical data and state for both Kubernetes and Romana.

The example contains two parts that need to be aligned:
* the `romana-etcd` Service
* the `romana-etcd` Deployment

The following details must be modified to match your cluster's settings:

* Service IP

  The Service IP for `romana-etcd` needs to be a valid value for your cluster's `--service-cluster-ip-range` CIDR, which is configured in your kube-apiserver.
  
  The value needs to be specified in the `romana-etcd` service for `clusterIP`, and also in the `romana-etcd` deployment template for the `--advertise-client-urls` option.

* Port

  The port for `romana-etcd` needs to be specified in the `romana-etcd` service for `port`, in the `romana-etcd` deployment template for the `--listen-client-urls` option, and in the `livenessProbe` for the `port`.

* Target Port

  The Target Port for `romana-etcd` needs to be specified in the `romana-etcd` service for `targetPort`, and in the `romana-etcd` deployment template for the `--advertise-client-urls` option.

* Labels

  The same labels should be used in the `romana-etcd` service for `selector` and in the `romana-etcd` deployment template for `labels` in the metadata.

* Placement

  The pod should be forced to run on a specific master node. If your master has a unique `node-role` label, then that can be used in the `romana-etcd` deployment template for the `nodeSelector`. Otherwise, the `nodeSelector` should be updated to match the key and value for the master node's `kubernetes.io/hostname`

  If your master node is _tainted_ to prevent pods being scheduled there, the `romana-etcd` deployment template should include the matching `toleration` to permit this pod.

### romana-daemon

The `romana-daemon` service is a central service used by other Romana components and provides an API for queries and changes. See the example [romana-daemon](specs/romana-daemon.yaml) YAML file.

The example contains two parts that need to be aligned:
* the `romana-daemon` Service
* the `romana-daemon` Deployment

The following details must be modified to match your cluster's settings:

* Service IP

  The Service IP for `romana-daemon` needs to be a valid value for your cluster's `--service-cluster-ip-range` CIDR, which is configured in your kube-apiserver.
  
  The value needs to be specified in the `romana-daemon` service for `clusterIP`.

* Placement

  The pod should be forced to run on a master node. If your master has a unique `node-role` label, then that can be used in the `romana-daemon` deployment template for the `nodeSelector`. Otherwise, the `nodeSelector` should be updated to match the key and value for the master node's `kubernetes.io/hostname`

  If your master node is _tainted_ to prevent pods being scheduled there, the `romana-daemon` deployment template should include the matching `toleration` to permit this pod.

* Cloud Provider Integration

  If your Kubernetes cluster is running in AWS and configured with `--cloud=aws`, then you should provide that option to the romana-daemon.

  This is done by uncommenting the `args` section and `--cloud` option in the `romana-daemon` deployment template.

  ```yaml
       args:
       - --cloud=aws
  ```

* Initial Network Configuration

  To complete the configuration of Romana, a [network topology](network-topology.md) needs to be configured. There are some built-in network topologies that will be used if possible, but in custom environments, this will need to be provided by the user.

  A built-in topology will be used if the `--cloud=aws` option was specified, or if the default Kubernetes Service IP is detected for `kops` or `kubeadm` (100.64.0.1 for kops, 10.96.0.1 for kubeadm).

  A user-defined network topology can be provided by
  - loading the network topology file into a configmap using kubectl

    ```bash
    kubectl -n kube-system create configmap romana-network-conf  --from-file=custom-network.json
    ```

  - mounting the configmap into the romana-daemon pod

  ```yaml
          volumeMounts:
          - name: romana-config-volume
            mountPath: /etc/romana/network
        volumes:
        - name: romana-config-volume
          configMap:
            name: romana-network-conf
  ```

  - specifying the path to that network topology file in the romana-daemon pod arguments

  ```yaml
          args:
          - --initial-network=/etc/romana/network/custom-network.json
  ```

  The path is a combination of the `mountPath` (eg: `/etc/romana/network`) and the filename inside the configmap (eg: `custom-network.json`).

  See the example [romana-daemon-custom-network](specs/romana-daemon-custom-network.yaml) YAML file.

* Network CIDR Overrides

  When using a built-in topology, the configuration specifies the CIDR that will be used for allocating IP addresses to pods.

  This value can be changed by specifying the `--network-cidr-overrides` option in the `romana-daemon` deployment template

  ```yaml
       args:
       - --network-cidr-overrides=romana-network=100.96.0.0/11
  ```

  The value for the CIDR should not overlap with any existing physical network ranges, or the Kubernetes `service-cluster-ip-range`.

### romana-listener

The `romana-listener` service is a background service that listens for events from the Kubernetes API Server and updates configuration in Romana. See the example [romana-listener](specs/romana-listener.yaml) YAML file.

The example contains four parts:
- the `romana-listener` ClusterRole
- the `romana-listener` ServiceAccount
- the `romana-listener` ClusterRoleBinding
- the `romana-listener` Deployment

The following details must be modified to match your cluster's settings:

* Placement

  The pod should be forced to run on a master node. If your master has a unique `node-role` label, then that can be used in the `romana-listener` deployment template for the `nodeSelector`. Otherwise, the `nodeSelector` should be updated to match the key and value for the master node's `kubernetes.io/hostname`

  If your master node is _tainted_ to prevent pods being scheduled there, the `romana-listener` deployment template should include the matching `toleration` to permit this pod.

### romana-agent

The `romana-agent` component is a local agent than runs on all Kubernetes nodes. It installs the CNI tools and configuration necessary to integrate Kubernetes CNI mechanics with Romana, and manages node-specific configuration for routing and policy. See the example [romana-agent](specs/romana-agent.yaml) YAML file.

The example contains four parts:
- the `romana-agent` ClusterRole
- the `romana-agent` ServiceAccount
- the `romana-agent` ClusterRoleBinding
- the `romana-agent` DaemonSet

The following details must be modified to match your cluster's settings:

* Service Cluster IP Range

  The Service Cluster IP Range for your Kubernetes cluster needs to be passed to the `romana-agent`, matching the value that is configured in your kube-apiserver.
  A default value will be used if the default Kubernetes Service IP is detected for `kops` or `kubeadm` (100.64.0.1 for kops, 10.96.0.1 for kubeadm).

  This value can be changed by specifying the `--service-cluster-ip-range` option in the `romana-daemon` deployment template

  ```yaml
       args:
       - --service-cluster-ip-range=100.64.0.0/13
  ```

* Placement

  The pod should be forced to run on all Kubernetes nodes. If your master node(s) are _tainted_ to prevent pods being scheduled there, the `romana-agent` daemonset template should include the matching `toleration` to permit this pod.

## Add-on Components for AWS

### romana-aws

The `romana-aws` service listens for node information from the Kubernetes API Server and disables the Source-Dest-Check attribute of the EC2 instances to allow pods to communicate between nodes. See the example [romana-aws](specs/romana-aws.yaml) YAML file.

The following details must be modified to match your cluster's settings:

* Placement
  The pod should be forced to run on a master node. If your master has a unique `node-role` label, then that can be used in the `romana-aws` deployment template for the `nodeSelector`. Otherwise, the `nodeSelector` should be updated to match the key and value for the master node's `kubernetes.io/hostname`

  If your master node is _tainted_ to prevent pods being scheduled there, the `romana-aws` deployment template should include the matching `toleration` to permit this pod.

* IAM Permissions

  The IAM role for your master node(s) needs to include the permission to modify EC2 Instance Attributes.


### romana-vpcrouter

The `romana-vpcrouter` service is responsible for creating and maintaining routes between Availability Zones and Subnets for a Kubernetes cluster in AWS. It combines node state information from Kubernetes, AWS and internal monitoring, and route assignments from Romana, and uses this to add and modify routes in the VPC Routing Tables.

The following details must be modified to match your cluster's settings:

* `romana-etcd` Service IP and Port

  The Service IP and Target Port for `romana-etcd` need to be specified in the `romana-vpcrouter` deployment template as values for the `--etcd_addr` and `--etcd_port` options.

* Placement
  The pod should be forced to run on a master node. If your master has a unique `node-role` label, then that can be used in the `romana-vpcrouter` deployment template for the `nodeSelector`. Otherwise, the `nodeSelector` should be updated to match the key and value for the master node's `kubernetes.io/hostname`

  If your master node is _tainted_ to prevent pods being scheduled there, the `romana-vpcrouter` deployment template should include the matching `toleration` to permit this pod.

* IAM Permissions

  The IAM role for your master node(s) needs to include the permission to describe EC2 Resources, list and modify VPCs, and list and modify RouteTables.

* Security Groups

  The vpcrouter component performs active liveness checks on cluster nodes. By default, it uses ICMPecho ("ping") requests for this purpose. Therefore, please ensure that your
security group ruless allow for cluster nodes to exchange those messages.


