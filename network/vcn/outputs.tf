output "id" {
  value = "${oci_core_virtual_network.CompleteVCN.id}"
}

output "etcd_subnet_ad1_id" {
  value = "${oci_core_subnet.etcdSubnetAD1.id}"
}

output "etcd_subnet_ad2_id" {
  value = "${oci_core_subnet.etcdSubnetAD2.id}"
}

output "etcd_subnet_ad3_id" {
  value = "${oci_core_subnet.etcdSubnetAD3.id}"
}

output "k8smaster_subnet_ad1_id" {
  value = "${oci_core_subnet.k8sMasterSubnetAD1.id}"
}

output "k8smaster_subnet_ad2_id" {
  value = "${oci_core_subnet.k8sMasterSubnetAD2.id}"
}

output "k8smaster_subnet_ad3_id" {
  value = "${oci_core_subnet.k8sMasterSubnetAD3.id}"
}

output "k8worker_subnet_ad1_id" {
  value = "${oci_core_subnet.k8sWorkerSubnetAD1.id}"
}

output "k8worker_subnet_ad2_id" {
  value = "${oci_core_subnet.k8sWorkerSubnetAD2.id}"
}

output "k8worker_subnet_ad3_id" {
  value = "${oci_core_subnet.k8sWorkerSubnetAD3.id}"
}

output "public_subnet_ad1_id" {
  value = "${oci_core_subnet.PublicSubnetAD1.0.id}"
}

output "public_subnet_ad2_id" {
  value = "${oci_core_subnet.PublicSubnetAD2.0.id}"
}

output "public_subnet_ad3_id" {
  value = "${oci_core_subnet.PublicSubnetAD3.0.id}"
}

output "nat_instance_private_ips" {
  value = ["${oci_core_instance.NATInstance.*.private_ip}"]
}

output "nat_instance_public_ips" {
  value = ["${oci_core_instance.NATInstance.*.public_ip}"]
}

output "network_access" {
  value = "${var.network_access}"
}
