output "ids" {
  value = ["${baremetal_core_instance.TFInstanceK8sWorker.*.id}"]
}

output "private_ips" {
  value = ["${baremetal_core_instance.TFInstanceK8sWorker.*.private_ip}"]
}

output "public_ips" {
  value = ["${baremetal_core_instance.TFInstanceK8sWorker.*.public_ip}"]
}

output "instance_host_names" {
  value = ["${baremetal_core_instance.TFInstanceK8sWorker.*.display_name}"]
}
