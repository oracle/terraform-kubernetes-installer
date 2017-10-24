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
