# Output the subnet ID

output "id" {
  value = "${oci_core_subnet.k8sMasterSubnet.id}"
}

output "dns_label" {
  value = "${oci_core_subnet.k8sMasterSubnet.dns_label}"
}
