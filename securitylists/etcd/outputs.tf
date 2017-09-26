# Output ID

output "id" {
  value = "${oci_core_security_list.EtcdSubnet.id}"
}

output "default_ssh_ingress_cidr" {
  value = "${var.default_ssh_ingress_cidr}"
}

output "default_etcd_cluster_ingress_cidr" {
  value = "${var.default_etcd_cluster_ingress_cidr}"
}
