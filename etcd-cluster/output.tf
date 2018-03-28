output "etcd_lb_ip" {
  value = ["${module.etcd-lb.ip_addresses}"]
}

output "etcd_public_ips" {
  value = "${compact(concat(module.instances-etcd-ad1.instance_public_ips,module.instances-etcd-ad2.instance_public_ips,module.instances-etcd-ad3.instance_public_ips))}"
}

output "etcd_private_ips" {
  value = "${concat(module.instances-etcd-ad1.private_ips,module.instances-etcd-ad2.private_ips,module.instances-etcd-ad3.private_ips)}"
}


output "endpoints" {
  value = "${var.etcd_lb_enabled == "true" ? 
      join(",",formatlist("http://%s:2379", module.etcd-lb.ip_addresses)) :
      join(",",formatlist("http://%s:2379", compact(concat(
      module.instances-etcd-ad1.private_ips, 
      module.instances-etcd-ad2.private_ips, 
      module.instances-etcd-ad3.private_ips)))) }"
}


