# Outputs

output "ip_addresses" {
  value = ["${baremetal_load_balancer.lb-etcd.ip_addresses}"]
}

output "load_balancer_id" {
  value = "${baremetal_load_balancer.lb-etcd.id}"
}

output "backendset_2379_name" {
  value = "${baremetal_load_balancer_backendset.lb-etcd-backendset-2379.name}"
}

output "backendset_2380_name" {
  value = "${baremetal_load_balancer_backendset.lb-etcd-backendset-2380.name}"
}
