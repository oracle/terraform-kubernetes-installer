# Output the subnet ID

output "id" {
  value = "${baremetal_core_subnet.k8sMasterSubnet.id}"
}

output "dns_label" {
  value = "${baremetal_core_subnet.k8sMasterSubnet.dns_label}"
}
