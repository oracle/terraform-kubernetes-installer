# Output the subnet ID

output "id" {
  value = "${baremetal_core_subnet.etcdSubnet.id}"
}

output "dns_label" {
  value = "${baremetal_core_subnet.etcdSubnet.dns_label}"
}
