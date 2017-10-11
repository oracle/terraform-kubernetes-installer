# Output the subnet ID

output "id" {
  value = "${oci_core_subnet.etcdSubnet.id}"
}

output "dns_label" {
  value = "${oci_core_subnet.etcdSubnet.dns_label}"
}
