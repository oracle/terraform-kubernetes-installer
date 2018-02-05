# Output ID

output "id" {
  value = "${baremetal_core_security_list.K8SMasterSubnet.id}"
}

output "default_ssh_ingress_cidr" {
  value = "${var.default_ssh_ingress_cidr}"
}

output "default_default_https_ingress_cidr" {
  value = "${var.default_https_ingress_cidr}"
}
