# Output the subnet ID

output "id" {
  value = "${baremetal_core_subnet.subnet.id}"
}

output "dns_label" {
  value = "${baremetal_core_subnet.subnet.dns_label}"
}
