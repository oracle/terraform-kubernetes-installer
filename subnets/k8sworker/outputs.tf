# Output the subnet ID

output "id" {
  value = "${oci_core_subnet.k8sWokerSubnet.id}"
}

output "dns_label" {
  value = "${oci_core_subnet.k8sWokerSubnet.dns_label}"
}
