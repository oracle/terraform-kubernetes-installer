#!/bin/bash

# Runs a few checks on the cluster. If you don't see Success and cluster info at the end, something's wrong.
# Example run: ./scripts/cluster-check.sh

# TODO handle scenario when control_plane_subnet_access = "private"

trap cleanup INT
trap cleanup EXIT

function cleanup {
	rm /tmp/instances_id_rsa
#	kubectl delete deployment nginx &>/dev/null
#	kubectl delete service nginx &>/dev/null
}

function log_msg() {
	local logger=$(basename "$0")
	printf "[${logger}] $1\n"
}

function check_tf_output() {
	local output_name="$1"
	if [[ -z $(terraform output $1) ]]; then
		echo terraform output variable $1 could not be resolved
		echo This script needs to be able to run: \"terraform output $1\"
		exit 1
	fi
}

# SSH to a node ($1), run command ($2)).
function ssh_run_command() {
	local node="$1"
	local command="$2"
	ssh -i /tmp/instances_id_rsa -oBatchMode=yes -oConnectTimeout=10 -o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null -q opc@${node} ${command} 2>&1 | tr -d '\r\n'
}

function check_ssh_connectivity() {
	log_msg "  Checking SSH connectivity to each node (from this host)..."
	check_tf_output "master_public_ips"
	for master in $(terraform output master_public_ips | sed "s/,/ /g"); do
		ret=$(ssh_run_command "${master}" "echo connected")
		if [[ $ret != "connected" ]]; then
			log_msg "  [FAILED] Could not ssh to master ${master}"
			log_msg "  Only IPs in $(terraform output master_ssh_ingress_cidr) are allowed to SSH to this node"
			log_msg "  If it is not correct, set master_ssh_ingress in terraform.tfvars to a CIDR that includes the IP \
             of this host and run terraform plan and apply"
			exit 1
		fi
	done

	check_tf_output "worker_public_ips"
	for worker in $(terraform output worker_public_ips | sed "s/,/ /g"); do
		ret=$(ssh_run_command "${worker}" "echo connected")
		if [[ $ret != "connected" ]]; then
			log_msg "  [FAILED] Could not ssh to worker ${worker}"
			log_msg "  Only IPs in $(terraform output worker_ssh_ingress_cidr) are allowed to SSH to this node"
			log_msg "  If it is not correct, set worker_ssh_ingress in terraform.tfvars to a CIDR that includes the IP \
           of this host and run terraform plan and apply"
			exit 1
		fi
	done

	check_tf_output "etcd_public_ips"
	for etcd in $(terraform output etcd_public_ips | sed "s/,/ /g"); do
		ret=$(ssh_run_command "${etcd}" "echo connected")
		if [[ $ret != "connected" ]]; then
			log_msg "  [FAILED] Could not ssh to etcd instance ${etcd}"
			log_msg "  Only IPs in $(terraform output etcd_ssh_ingress_cidr) are allowed to SSH to this node"
			log_msg "  If it is not correct, set etcd_ssh_ingress in terraform.tfvars to a CIDR that includes the IP \
           of this host and run terraform plan and apply"
			exit 1
		fi
	done
}

function check_cloud_init_finished() {
	log_msg "  Checking whether instance bootstrap has completed on each node..."
	for master in $(terraform output master_public_ips | sed "s/,/ /g"); do
		ret=$(ssh_run_command "${master}" "sudo test -e /var/lib/cloud/instance/boot-finished && echo true")
		if [[ $ret != "true" ]]; then
			log_msg "  [FAILED] cloud-init has not finished running on master ${master}"
			log_msg "  If this does not complete soon, log into the BMC instance and examine the /var/log/cloud-init-output.log file."
			exit 1
		fi
		ret=$(ssh_run_command "${master}" "sudo grep --only-matching -m 1 'Finished running setup.sh' /root/setup.log")
		if [[ $ret != "Finished running setup.sh" ]]; then
			log_msg "  [FAILED] cloud-init has not run successfully on master ${master}"
			log_msg "  Log into the BMC instance and examine the /root/setup.log file."
			exit 1
		fi
	done

	for worker in $(terraform output worker_public_ips | sed "s/,/ /g"); do
		ret=$(ssh_run_command "${worker}" "sudo test -e /var/lib/cloud/instance/boot-finished && echo true")
		if [[ $ret != "true" ]]; then
			log_msg "  [FAILED] cloud-init has not finished running on worker ${worker}"
			log_msg "  If this does not complete soon, log into the BMC instance and examine the /root/setup.log file."
			exit 1
		fi
		ret=$(ssh_run_command "${worker}" "sudo grep --only-matching -m 1 'Finished running setup.sh' /root/setup.log")
		if [[ $ret != "Finished running setup.sh" ]]; then
			log_msg "  [FAILED] cloud-init has not run successfully on worker ${worker}"
			log_msg "  Log into the BMC instance and examine the /root/setup.log file."
			exit 1
		fi
	done

	for etcd in $(terraform output etcd_public_ips | sed "s/,/ /g"); do
		ret=$(ssh_run_command "${etcd}" "sudo test -e /var/lib/cloud/instance/boot-finished && echo true")
		if [[ $ret != "true" ]]; then
			log_msg "  [FAILED] cloud-init has not finished running on etcd node ${etcd}"
			log_msg "  If this does not complete soon, log into the BMC instance and examine the /root/setup.log file."
			exit 1
		fi
	done
}

function check_system_services() {

	log_msg "  Checking whether expected system services are running on each node..."
	for master in $(terraform output master_public_ips | sed "s/,/ /g"); do
		ret=$(ssh_run_command "${master}" "sudo systemctl status docker 2>&1 | grep --only-matching 'Active: active' | tr -d '\r\n'")
		if [[ $ret != "Active: active" ]]; then
			log_msg "  [FAILED] expected docker service is not running on master $master"
			exit 1
		fi
		ret=$(ssh_run_command "${master}" "sudo systemctl status kubelet 2>&1 | grep --only-matching 'Active: active' | tr -d '\r\n'")
		if [[ $ret != "Active: active" ]]; then
			log_msg "  [FAILED] expected kubelet service is not running on master $master"
			exit 1
		fi

		ret=$(ssh_run_command "${master}" "sudo docker ps | grep --only-matching \"hyperkube proxy\" | tr -d '\r\n'")
		if [[ $ret != "hyperkube proxy" ]]; then
			log_msg "  [FAILED] expected hyperkube proxy service is not running on master $master"
			exit 1
		fi
	done

	for worker in $(terraform output worker_public_ips | sed "s/,/ /g"); do
		ret=$(ssh_run_command "${worker}" "sudo systemctl status docker 2>&1 | grep --only-matching 'Active: active' | tr -d '\r\n'")
		if [[ $ret != "Active: active" ]]; then
			log_msg "  [FAILED] expected docker service is not running on worker $worker"
			exit 1
		fi
		ret=$(ssh_run_command "${worker}" "sudo systemctl status kubelet 2>&1 | grep --only-matching 'Active: active' | tr -d '\r\n'")
		if [[ $ret != "Active: active" ]]; then
			log_msg "  [FAILED] expected kubelet service is not running on worker $worker"
			exit 1
		fi
		ret=$(ssh_run_command "${worker}" "sudo docker ps | grep --only-matching \"hyperkube proxy\" | tr -d '\r\n'")
		if [[ $ret != "hyperkube proxy" ]]; then
			log_msg "  [FAILED] expected hyperkube proxy service is not running on worker $worker"
			exit 1
		fi

	done

	for etcd in $(terraform output etcd_public_ips | sed "s/,/ /g"); do
		ret=$(ssh_run_command "${etcd}" "sudo systemctl status docker 2>&1 | grep --only-matching 'Active: active' | tr -d '\r\n'")
		if [[ $ret != "Active: active" ]]; then
			log_msg "  [FAILED] expected docker service is not running on etcd $etcd"
			exit 1
		fi
	done

}

function check_get_nodes() {
	log_msg "  Running 'kubectl get nodes' a number of times through the master LB..."
	expected_nodes=$(expr $(terraform output worker_public_ips | tr -cd , | wc -c) + 1)
	for i in {1..20}; do
		count=$(kubectl get nodes --no-headers 2>/dev/null | grep "Ready" | wc -l)
		if [ "$count" -lt $expected_nodes ]; then
			log_msg "  [FAILED] kubectl get nodes reported less healthy nodes than expected"
			kubectl get nodes
			exit 1
		fi
	done
}

function check_kube-dns() {
	log_msg "  Checking status of kube-dns pod..."
	output=$(kubectl get pods --namespace=kube-system -l k8s-app=kube-dns 2>&1 | grep kube-dns | awk '{print $3}')
	if [[ $output != "Running" ]]; then
		log_msg "  [FAILED] kube-dns is not running in the cluster"
		exit 1
	fi

	output=$(kubectl get pods --namespace=kube-system -l k8s-app=kube-dns 2>&1 | grep kube-dns | awk '{print $2}')
	if [[ $output != "3/3" ]]; then
		log_msg "  [FAILED] expected 3/3 kube-dns pods to be running in the cluster"
		exit 1
	fi
}

function check_kube-flannel() {
	log_msg "  Checking status of kube-flannel pod..."
	output=$(kubectl get pods --namespace=kube-system -l app=flannel 2>&1 | grep kube-flannel | awk '{print $3}' | grep -vi running)
	if [[ ! -z $output ]]; then
		log_msg "  [FAILED] kube-flannel is not running in the cluster"
		exit 1
	fi
}

function check_nginx_deployment() {
	log_msg "  Checking an app deployment of nginx exposed as a service..."
	expected_nodes=$(expr $(terraform output worker_public_ips | tr -cd , | wc -c) + 2)
	kubectl run nginx --image="nginx" --port=80 --replicas=${expected_nodes} 1>/dev/null
	kubectl expose deployment nginx --type NodePort 1>/dev/null

	nodePort="UNSET"
	max_tries=0
	until [ $nodePort != "UNSET" ] || [ $max_tries -eq 10 ]; do
		nodePort=$(kubectl get svc nginx --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
		max_tries=$((max_tries + 1))
	done

	if [[ $nodePort == "UNSET" ]]; then
		log_msg "  [FAILED] could not retrieve the NodePort of the nginx service"
		exit 1
	fi

	# Avoid possible hang if port is not ready
	sleep 10
    for i in {1..5}; do
	    for worker in $(terraform output worker_public_ips | sed "s/,/ /g"); do
		    output=$(curl --max-time 30 http://$worker:$nodePort 2>/dev/null)
            if [[ -z "$output" ]]; then
			    log_msg "   [FAILED] nginx deployment service is not accessible on http://$worker:$nodePort"
			    exit 1
            fi
		    if [[ $output != *"Welcome to nginx!"* ]]; then
			    log_msg "  [FAILED] nginx deployment service is not accessible on http://$worker:$nodePort"
		    	exit 1
	    	fi
    	done
    done
}

function print_success() {
	cat <<EOF

The Kubernetes cluster is up and appears to be healthy.
$(kubectl cluster-info)
EOF
}

############ Main ############

if [[ -f cluster-check.sh ]]; then
	log_msg "  Please run this script from the repository root directory."
	exit 1
fi

terraform output ssh_private_key >/tmp/instances_id_rsa
chmod 600 /tmp/instances_id_rsa

control_plane_subnet_access=$(terraform output control_plane_subnet_access)
if [[ $control_plane_subnet_access == "private" ]]; then
	echo This script does not currently support checking private clusters
	exit 1
fi

log_msg "Running some basic checks on Kubernetes cluster...."

check_ssh_connectivity
check_cloud_init_finished
check_system_services
check_get_nodes
check_kube-dns
check_kube-flannel
check_nginx_deployment
print_success

exit 0
