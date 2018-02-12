# Output the private and public IPs of the instance

output "ids" {
  value = ["${baremetal_core_instance.TFInstanceEtcd.*.id}"]
}

output "private_ips" {
  value = ["${baremetal_core_instance.TFInstanceEtcd.*.private_ip}"]
}

output "public_ips" {
  value = ["${baremetal_core_instance.TFInstanceEtcd.*.public_ip}"]
}
