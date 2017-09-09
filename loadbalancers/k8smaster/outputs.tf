# Outputs

output "ip_addresses" {
  value = ["${baremetal_load_balancer.lb-k8smaster.ip_addresses}"]
}

output "load_balancer_id" {
  value = "${baremetal_load_balancer.lb-k8smaster.id}"
}

output "backendset_name" {
  value = "${baremetal_load_balancer_backendset.lb-k8smaster-https.name}"
}
