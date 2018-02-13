output "ip_address" {
  value = "${baremetal_load_balancer.lb-k8smaster.ip_addresses[0]}"
}
