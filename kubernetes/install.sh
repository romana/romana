#!/bin/bash

declare -A ROMANA_GATES
declare -A ROMANA_ROUTES

is_master () {
	[[ $INSTANCE_ID == $MASTER_ID ]] && return 0 || return 1
	
}

get_romana_binaries () {
	for bin in root ipam agent tenant topology tenant; do 
		s3_prefix="https://s3-us-west-1.amazonaws.com"
		s3_bucket=romana-binaries
		wget "$s3_prefix/$s3_bucket/core/latest/origin/$CORE_BRANCH/$bin" -O "/bin/$bin"
		chmod +x /bin/$bin
	done
}

configure_romana () {
	echo "In configure_romana"

	if is_master; then
		test -f /home/ubuntu/romana.conf || cp /home/ubuntu/romana/kubernetes/romana.conf.example /home/ubuntu/romana.conf
		sed -i "s/__MASTER_IP__/$MASTER_IP/g" /home/ubuntu/romana.conf
		if ! test -f /tmp/romana_mysql.done; then
			mysql -u root -psecrete  < /home/ubuntu/romana/kubernetes/romana.sqldump
			touch /tmp/romana_mysql.done
		fi
		cp /home/ubuntu/romana/kubernetes/romana.rc /root/romana.rc
	else
		cp /home/ubuntu/romana/kubernetes/romana.agent.rc /root/romana.rc
	fi

	sysctl net.ipv4.conf.all.proxy_arp=1
	sysctl net.ipv4.conf.default.proxy_arp=1

	sed -i "s/__MASTER_IP__/$MASTER_IP/g" /root/romana.rc
}

configure_cni_plugin () {
	cp -r /home/ubuntu/romana/kubernetes/etc/cni /etc/
	sed -i "s/__MASTER_IP__/$MASTER_IP/g" /etc/cni/net.d/10-romana.conf
	mkdir -p /opt/cni/bin/
	cp -f /home/ubuntu/kube/CNI/romana /opt/cni/bin/romana
	chmod +x /opt/cni/bin/romana
}

start_mysql () {
	is_master || return 0	

	mysqladmin password secrete 2>&1 > /dev/null
	service mysql restart
} 
	
create_topology_record () {
	IP=$1
	NAME=$2
	ROMANA_NET=$3
	AGENT_PORT=$4

        REQ='{"Ip" : "__IP__", "name": "__NAME__", "romana_ip" : "__ROMANA_IP__", "agent_port" : __PORT__ }'
        REQ=$(echo $REQ | sed "s/__IP__/$IP"/)
        REQ=$(echo $REQ | sed "s/__NAME__/$NAME/")
        REQ=$(echo $REQ | sed "s+__ROMANA_IP__+$ROMANA_NET+")
        REQ=$(echo $REQ | sed "s/__PORT__/$AGENT_PORT/")
        echo curl -v -H "Accept: application/json" -H "Content-Type: application/json" http://$MASTER_IP:9603/hosts -XPOST -d "$REQ"
        curl -v -H "Accept: application/json" -H "Content-Type: application/json" http://$MASTER_IP:9603/hosts -XPOST -d "$REQ"
}

configure_topology () {
	ROMANA_IDX=0
	for id in  $MASTER_ID $ASG_INSTANCES; do
		ROMANA_ROUTE="10.${ROMANA_IDX}.0.0/16"
		ROMANA_ROUTES[$id]="$ROMANA_ROUTE"
		ROMANA_GATE="10.${ROMANA_IDX}.0.1/16"
		ROMANA_GATES[$id]="$ROMANA_GATE"
		[[ "$id" == "$MASTER_ID" ]] && ip=$MASTER_IP || ip="${ASG_IPS[$id]}"

		# on slaves we only want to fill in arrays above
		# but on master actually want to create topology records
		if is_master; then
			create_topology_record "$ip" "$id" "$ROMANA_GATE" "9604"
		fi
		ROMANA_IDX=$(( ROMANA_IDX +1 ))
	done
}

configure_gate_and_routes () {
	echo "In configure_gate_and_routes"
	for id in $MASTER_ID $ASG_INSTANCES; do 
		if [[ "$id" == "$INSTANCE_ID" ]]; then
			echo "Creating gate for $id -> ${ROMANA_GATES[$id]}"
			create_romana_gateway "${ROMANA_GATES[$id]}"
		else
			[[ "$id" == "$MASTER_ID" ]] && ip=$MASTER_IP || ip="${ASG_IPS[$id]}"		
			echo "Creating route for $id ${ROMANA_ROUTES[$id]} -> ip"
			create_route "${ROMANA_ROUTES[$id]}" "$ip"
		fi
	done
}


register_node () {
	is_master && return 0 # master registered by default somehow

	sed -i "s/__NODE__/$INSTANCE_ID/g" /home/ubuntu/romana/kubernetes/etc/kubernetes/node.json
	until nc -z ${MASTER_IP} 8080; do
		echo "In register_node, waiting for master to show up"
		sleep 10
	done;
	kubectl -s "${MASTER_IP}:8080" create -f /home/ubuntu/romana/kubernetes/etc/kubernetes/node.json
}
	
create_romana_gateway () {
	if ! ip link | grep -q romana-gw; then
		ip link add romana-gw type dummy
	fi
	
	ifconfig romana-gw inet "$1" up
}

create_route () {
	ip ro add $1 via $2
}

get_kubernetes () {
	test -f /root/kubernetes.tar.gz || wget https://github.com/kubernetes/kubernetes/releases/download/v1.2.0-alpha.6/kubernetes.tar.gz -O /root/kubernetes.tar.gz
	test -d /root/kubernetes || tar -zxvf /root/kubernetes.tar.gz -C /root
	cd /root/kubernetes/cluster/ubuntu && ./download-release.sh
	ln -s /root/kubernetes/cluster/ubuntu/binaries/kubectl /bin/
	for i in etcd  etcdctl flanneld  kube-apiserver  kube-controller-manager  kube-scheduler; do 
		ln -s /root/kubernetes/cluster/ubuntu/binaries/master/$i /bin
	done
	for i in kubelet  kube-proxy; do 
		ln -s /root/kubernetes/cluster/ubuntu/binaries/minion/$i /bin
	done
	ln -s /root/kubernetes /home/ubuntu || :
}
	
configure_kubernetes_screen () {
	if is_master; then
		cp /home/ubuntu/romana/kubernetes/etc/kubernetes/k8s.rc /root/kubernetes.rc
	else
		cp /home/ubuntu/romana/kubernetes/etc/kubernetes/k8s.node.rc /root/kubernetes.rc
	fi

	sed -i "s/__MASTER_IP__/$MASTER_IP/g" /root/kubernetes.rc
	sed -i "s/__MASTER_ID__/$INSTANCE_ID/g" /root/kubernetes.rc

}
	
start_kubernetes_screen () {
	if ! screen -ls | grep -q kubernetes; then
		screen -AmdS kubernetes -c /root/kubernetes.rc
	fi
}

start_romana_screen () {
	if ! screen -ls | grep -q romana; then
		screen -AmdS romana -c /root/romana.rc
	fi
}

register_network_policy_resource () {
	if is_master; then
		until nc -z ${MASTER_IP} 8080; do
			echo "In Register network policy resource, waiting for master to show up"
			sleep 10
		done;
		kubectl -s "${MASTER_IP}:8080" create --validate=false -f /home/ubuntu/romana/kubernetes/romana-tpr.yaml > /tmp/romana-tpr.log 2>&1 
	fi
}
	
#main 
	get_kubernetes
	get_romana_binaries
	start_mysql
	configure_romana
	start_romana_screen
	configure_topology
	configure_cni_plugin
	configure_kubernetes_screen
	start_kubernetes_screen
	configure_gate_and_routes
	register_node
	register_network_policy_resource
