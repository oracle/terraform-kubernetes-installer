# Output ID

output "id" {
  value = "${oci_core_security_list.K8SWorkerSubnet.id}"
}

output "default_ssh_ingress_cidr" {
  value = "${var.default_ssh_ingress_cidr}"
}

output "default_default_node_port_ingress_cidr" {
  value = "${var.default_node_port_ingress_cidr}"
}
