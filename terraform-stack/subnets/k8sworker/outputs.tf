# Output the subnet ID

output "id" {
  value = "${baremetal_core_subnet.k8sWokerSubnet.id}"
}

output "dns_label" {
  value = "${baremetal_core_subnet.k8sWokerSubnet.dns_label}"
}
