output "ssh_private_key" {
  value = "${module.k8s-tls.ssh_private_key}"
}

output "etcd_public_ips" {
  value = "${concat(module.instances-etcd-ad1.instance_public_ips,module.instances-etcd-ad2.instance_public_ips,module.instances-etcd-ad3.instance_public_ips)}"
}

output "master_public_ips" {
  value = "${concat(module.instances-k8smaster-ad1.public_ips,module.instances-k8smaster-ad2.public_ips,module.instances-k8smaster-ad3.public_ips )}"
}

output "worker_public_ips" {
  value = "${concat(module.instances-k8sworker-ad1.public_ips,module.instances-k8sworker-ad2.public_ips,module.instances-k8sworker-ad3.public_ips )}"
}

output "region" {
  value = "${var.region}"
}