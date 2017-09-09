output "ids" {
  value = ["${baremetal_core_instance.TFInstanceK8sMaster.*.id}"]
}

output "private_ips" {
  value = ["${baremetal_core_instance.TFInstanceK8sMaster.*.private_ip}"]
}

output "public_ips" {
  value = ["${baremetal_core_instance.TFInstanceK8sMaster.*.public_ip}"]
}
