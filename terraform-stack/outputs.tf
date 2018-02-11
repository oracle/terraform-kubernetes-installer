output "k8s_etcd_public_ips" {
  value = "${concat(module.instances-etcd-ad1.instance_public_ips,module.instances-etcd-ad2.instance_public_ips,module.instances-etcd-ad3.instance_public_ips)}"
}

output "k8s_master_public_ips" {
  value = "${concat(module.instances-k8smaster-ad1.public_ips,module.instances-k8smaster-ad2.public_ips,module.instances-k8smaster-ad3.public_ips )}"
}

output "k8s_worker_public_ips" {
  value = "${concat(module.instances-k8sworker-ad1.public_ips,module.instances-k8sworker-ad2.public_ips,module.instances-k8sworker-ad3.public_ips )}"
}

output "region" {
  value = "${var.region}"
}

output "ssh_private_key" {
  value = "${module.tls.ssh_private_key}"
}

output "root_ca_pem" {
  value = "${module.k8s-tls.root_ca_pem}"
}

output "root_ca_key" {
  value = "${module.k8s-tls.root_ca_key}"
}

output "api_server_private_key_pem" {
  value = "${module.k8s-tls.api_server_private_key_pem}"
}

output "api_server_cert_pem" {
  value = "${module.k8s-tls.api_server_cert_pem}"
}

