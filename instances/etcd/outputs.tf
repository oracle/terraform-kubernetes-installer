# Output the private and public IPs of the instance

output "ids" {
  value = ["${baremetal_core_instance.TFInstanceEtcd.*.id}"]
}

output "hostname_label" {
  value = "${baremetal_core_instance.TFInstanceEtcd.hostname_label}"
}

output "private_ips" {
  value = ["${baremetal_core_instance.TFInstanceEtcd.*.private_ip}"]
}

output "instance_public_ips" {
  value = ["${baremetal_core_instance.TFInstanceEtcd.*.public_ip}"]
}
