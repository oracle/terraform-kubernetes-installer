output "master_instance_ids" {
  value = "${concat(module.instances-k8smaster-ad1.ids,module.instances-k8smaster-ad2.ids,module.instances-k8smaster-ad3.ids )}"
}

output "worker_instance_ids" {
  value = "${concat(module.instances-k8sworker-ad1.ids,module.instances-k8sworker-ad2.ids,module.instances-k8sworker-ad3.ids )}"
}

output "master_lb_id" {
  value = "${module.k8smaster-public-lb.load_balancer_id}"
}

output "master_lb_backendset_name" {
  value = "${module.k8smaster-public-lb.backendset_name}"
}

output "etcd_lb_id" {
  value = "${module.etcd-private-lb.load_balancer_id}"
}

output "etcd_lb_backendset_2379_name" {
  value = "${module.etcd-private-lb.backendset_2379_name}"
}

output "etcd_lb_backendset_2380_name" {
  value = "${module.etcd-private-lb.backendset_2380_name}"
}

output "etcd_security_list_id" {
  value = "${module.security-list-etcd.id}"
}

output "master_security_list_id" {
  value = "${module.security-list-k8smaster.id}"
}

output "worker_security_list_id" {
  value = "${module.security-list-k8sworker.id}"
}

output "vcn_id" {
  value = "${module.vcn.id}"
}

output "vcn_route_for_complete_id" {
  value = "${module.vcn.route_for_complete_id}"
}

output "vcn_dhcp_options_id" {
  value = "${module.vcn.dhcp_options_id}"
}

output "etcd_subnet_dns_labels" {
  value = ["${module.subnet-etcd-ad1.dns_label}", "${module.subnet-etcd-ad2.dns_label}", "${module.subnet-etcd-ad3.dns_label}"]
}

output "etcd_subnet_ids" {
  value = ["${module.subnet-etcd-ad1.id}", "${module.subnet-etcd-ad2.id}", "${module.subnet-etcd-ad3.id}"]
}

output "master_subnet_ids" {
  value = ["${module.subnet-k8sMasterSubnetAd1.id}", "${module.subnet-k8sMasterSubnetAd2.id}", "${module.subnet-k8sMasterSubnetAd3.id}"]
}

output "worker_subnet_ids" {
  value = ["${module.subnet-k8sWorkerSubnetAd1.id}", "${module.subnet-k8sWorkerSubnetAd2.id}", "${module.subnet-k8sWorkerSubnetAd3.id}"]
}

output "worker_ssh_ingress_cidr" {
  value = "${module.security-list-k8sworker.default_ssh_ingress_cidr}"
}

output "worker_node_port_ingress_cidr" {
  value = "${module.security-list-k8sworker.default_default_node_port_ingress_cidr}"
}

output "master_ssh_ingress_cidr" {
  value = "${module.security-list-k8smaster.default_ssh_ingress_cidr}"
}

output "master_https_ingress_cidr" {
  value = "${module.security-list-k8smaster.default_default_https_ingress_cidr}"
}

output "etcd_ssh_ingress_cidr" {
  value = "${module.security-list-etcd.default_ssh_ingress_cidr}"
}

output "root_ca_pem" {
  value = "${module.k8s-tls.root_ca_pem}"
}

output "root_ca_key" {
  value = "${module.k8s-tls.root_ca_key}"
}

output "api_server_private_key_pem" {
  value = "${module.k8s-tls.api_server_private_key_pem}"
}

output "api_server_cert_pem" {
  value = "${module.k8s-tls.api_server_cert_pem}"
}

output "api_server_admin_token" {
  value = "${module.k8s-tls.api_server_admin_token}"
}

output "ssh_private_key" {
  value = "${module.k8s-tls.ssh_private_key}"
}

output "ssh_public_key_openssh" {
  value = "${module.k8s-tls.ssh_public_key_openssh}"
}

output "etcd_lb_ip" {
  value = ["${module.etcd-private-lb.ip_addresses}"]
}

output "etcd_public_ips" {
  value = "${concat(module.instances-etcd-ad1.instance_public_ips,module.instances-etcd-ad2.instance_public_ips,module.instances-etcd-ad3.instance_public_ips)}"
}

output "etcd_private_ips" {
  value = "${concat(module.instances-etcd-ad1.private_ips,module.instances-etcd-ad2.private_ips,module.instances-etcd-ad3.private_ips)}"
}

output "master_lb_ip" {
  value = ["${module.k8smaster-public-lb.ip_addresses}"]
}

output "master_public_ips" {
  value = "${concat(module.instances-k8smaster-ad1.public_ips,module.instances-k8smaster-ad2.public_ips,module.instances-k8smaster-ad3.public_ips )}"
}

output "master_private_ips" {
  value = "${concat(module.instances-k8smaster-ad1.private_ips,module.instances-k8smaster-ad2.private_ips,module.instances-k8smaster-ad3.private_ips )}"
}

output "worker_public_ips" {
  value = "${concat(module.instances-k8sworker-ad1.public_ips,module.instances-k8sworker-ad2.public_ips,module.instances-k8sworker-ad3.public_ips )}"
}

output "worker_private_ips" {
  value = "${concat(module.instances-k8sworker-ad1.private_ips,module.instances-k8sworker-ad2.private_ips,module.instances-k8sworker-ad3.private_ips )}"
}

output "kubeconfig" {
  value = "${module.kubeconfig.kubeconfig}"
}
