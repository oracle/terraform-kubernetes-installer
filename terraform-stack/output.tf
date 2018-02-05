output "ssh_private_key" {
  value = "${module.tls.ssh_private_key}"
}

output "ssh_public_key_openssh" {
  value = "${module.tls.ssh_public_key_openssh}"
}

output "logging_instance_public_ip" {
  value = "${baremetal_core_instance.logging-instance.public_ip}"
}

output "monitoring_instance_public_ip" {
  value = "${baremetal_core_instance.monitoring-instance.public_ip}"
}

output "vcn_id" {
  value = "${module.vcn.id}"
}

output "region" {
  value = "${var.region}"
}