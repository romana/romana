#!/bin/bash

INSTANCE_TAGS=""
STACK_NAME=""
ROMANA_BRANCH=""
CORE_BRANCH=""
MASTER_IP=""
MASTER_ID=""
AWS_REGION=""
STACK_RESOURCES="" 
NEWPASS=""
ASG_NAME=""
ASG_RESOURCES=""
ASG_INSTANCES=""
ASG_DESIRED_CAP=""
declare -A ASG_IPS
SSH_CONFIG='SG9zdCAqClN0cmljdEhvc3RLZXlDaGVja2luZyBubwo='
U_HOME="/home/ubuntu"
R_HOME="${U_HOME}/romana"
A_HOME="${R_HOME}/POC/ansible" #TODO prbably not needed

create_user_ssh_config () {
	mkdir -p $U_HOME/.ssh
	echo $SSH_CONFIG | base64 -d > $U_HOME/.ssh/config
	chown ubuntu:ubuntu $U_HOME/.ssh/config
}

install_packages () { 
	apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get install -y python-pip jq mysql-server git iptables  vim docker.io
	pip install awscli simplejson
	which nsenter || docker run -v /usr/local/bin:/target jpetazzo/nsenter
}

get_instance_tags () {
	INSTANCE_ID=$(ec2metadata --instance-id)
	AZ=$(ec2metadata --availability-zone)
	AWS_REGION=$( echo $AZ | sed 's/.$//' )
	INSTANCE_TAGS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $AWS_REGION --query "Reservations[0].Instances[0].Tags")
}

get_stack_name () {
	STACK_NAME=$( echo $INSTANCE_TAGS | jq '.[] | if .Key == "aws:cloudformation:stack-name" then .Value else "" end ' -r | xargs )
}

get_romana_branch () {
	STACK_PARAMETERS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $AWS_REGION --query "Stacks[0].Parameters")
	ROMANA_BRANCH=$(echo $STACK_PARAMETERS | jq '.[] | if .ParameterKey=="RomanaBranch" then .ParameterValue else "" end' -r | xargs)
	CORE_BRANCH=$(echo $STACK_PARAMETERS | jq '.[] | if .ParameterKey=="CoreBranch" then .ParameterValue else "" end' -r | xargs)
}

get_stack_resources () {
	STACK_RESOURCES=$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME --region $AWS_REGION)
}

get_ip_addresses () {
	MASTER_ID=$(echo $STACK_RESOURCES | jq -r '.StackResources[] | if .LogicalResourceId=="MasterNode" then .PhysicalResourceId else empty end')
	MASTER_IP=$(aws ec2 describe-instances --instance-ids $MASTER_ID --region $AWS_REGION --output text --query "Reservations[*].Instances[*].PrivateIpAddress" | xargs)
	ASG_DESIRED_CAP=$(echo $ASG_RESOURCES | jq '.AutoScalingGroups[].DesiredCapacity' -r)
	wait_for_asg_instances
	for id in $ASG_INSTANCES; do 
		IP=$(aws ec2 describe-instances --instance-ids $id --region $AWS_REGION --output text --query "Reservations[*].Instances[*].PrivateIpAddress")
		ASG_IPS[$id]=$IP
	done
}

wait_for_asg_instances() {
	for i in `seq 1 12`; do
		echo "Wainiting for ASG instances to come up"
		ASG_INSTANCES=$(echo $ASG_RESOURCES | jq '.AutoScalingGroups[].Instances[].InstanceId' -r | xargs)
		COUNT=$(echo $ASG_INSTANCES | wc -w)
		if [[ $COUNT -lt $ASG_DESIRED_CAP ]]; then
			echo -n .
		else 
			echo done
			return 0
		fi
		sleep 10
	done
	echo "Autoscaling instances failed to show up"
	exit 1
}

get_asg_name () {
	ASG_NAME=$(echo $STACK_RESOURCES | jq '.StackResources[] | if .LogicalResourceId=="ComputeGroup" then .PhysicalResourceId else "" end' -r |xargs)
}

get_asg_resources () {
	ASG_RESOURCES=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --region $AWS_REGION)
}

collect_aws_metadata () {
	echo "In collect_aws_metadata - begin"
	print_debug	
	get_instance_tags
	get_stack_name
	get_romana_branch
	get_stack_resources
	get_asg_name
	get_asg_resources
	get_ip_addresses
	print_debug
}

print_debug () {
	echo "INSTANCE_TAGS=$INSTANCE_TAGS"
	echo "STACK_NAME=${STACK_NAME}."
        echo "ASG_NAME=$ASG_NAME"
        echo "ASG_IPS=$ASG_IPS"
	for id in $ASG_INSTANCES; do echo "Compute node $id ${ASG_IPS[$id]}"; done
	echo "ROMANA_BRANCH=$ROMANA_BRANCH"
	echo "MASTER_IP=$MASTER_IP"
	echo "AWS_REGION=$AWS_REGION"
}
	
clone_romana () {
	if ! test -d $R_HOME; then
	    sudo su - ubuntu -c "git clone https://github.com/romana/romana --branch=$ROMANA_BRANCH $R_HOME"
	fi
}


call_install_script () {
	source /home/ubuntu/romana/kubernetes/install.sh
}
	
create_host_records () {
	ensure_line_in_file "$MASTER_IP $MASTER_ID" /etc/hosts
	for id in $ASG_INSTANCES; do
		ensure_line_in_file "${ASG_IPS[$id]} $id" /etc/hosts
	done
}

ensure_line_in_file () { # $1 line to install into file; $2 target file
	if ! grep -q "^$1" $2; then
		echo $1 >> $2
	fi
}

disable_aws_firewall () {
	aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --no-source-dest-check --region $AWS_REGION
}
	
#main 
	install_packages
	collect_aws_metadata
	create_host_records
	create_user_ssh_config
	clone_romana
	disable_aws_firewall
	call_install_script
