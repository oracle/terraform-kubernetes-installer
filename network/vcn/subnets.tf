resource "oci_core_subnet" "etcdSubnetAD1" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block                 = "10.0.20.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "${var.label_prefix}etcdSubnetAD1"
  dns_label                  = "etcdsubnet1"
  vcn_id                     = "${oci_core_virtual_network.CompleteVCN.id}"
  route_table_id             = "${oci_core_route_table.MgmtRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CompleteVCN.default_dhcp_options_id}"
  security_list_ids          = ["${concat(list(oci_core_security_list.EtcdSubnet.id), var.additional_etcd_security_lists_ids)}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "etcdSubnetAD2" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block                 = "10.0.21.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "${var.label_prefix}etcdSubnetAD2"
  dns_label                  = "etcdsubnet2"
  vcn_id                     = "${oci_core_virtual_network.CompleteVCN.id}"
  route_table_id             = "${oci_core_route_table.MgmtRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CompleteVCN.default_dhcp_options_id}"
  security_list_ids          = ["${concat(list(oci_core_security_list.EtcdSubnet.id), var.additional_etcd_security_lists_ids)}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "etcdSubnetAD3" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  cidr_block                 = "10.0.22.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "${var.label_prefix}etcdSubnetAD3"
  dns_label                  = "etcdsubnet3"
  vcn_id                     = "${oci_core_virtual_network.CompleteVCN.id}"
  route_table_id             = "${oci_core_route_table.MgmtRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CompleteVCN.default_dhcp_options_id}"
  security_list_ids          = ["${concat(list(oci_core_security_list.EtcdSubnet.id), var.additional_etcd_security_lists_ids)}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "k8sMasterSubnetAD1" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block                 = "10.0.30.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "${var.label_prefix}k8sMasterSubnetAD1"
  dns_label                  = "k8smasterad1"
  vcn_id                     = "${oci_core_virtual_network.CompleteVCN.id}"
  route_table_id             = "${oci_core_route_table.MgmtRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CompleteVCN.default_dhcp_options_id}"
  security_list_ids          = ["${concat(list(oci_core_security_list.K8SMasterSubnet.id), var.additional_k8smaster_security_lists_ids)}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "k8sMasterSubnetAD2" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block                 = "10.0.31.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "${var.label_prefix}k8sMasterSubnetAD2"
  dns_label                  = "k8smasterad2"
  vcn_id                     = "${oci_core_virtual_network.CompleteVCN.id}"
  route_table_id             = "${oci_core_route_table.MgmtRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CompleteVCN.default_dhcp_options_id}"
  security_list_ids          = ["${concat(list(oci_core_security_list.K8SMasterSubnet.id), var.additional_k8smaster_security_lists_ids)}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "k8sMasterSubnetAD3" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  cidr_block                 = "10.0.32.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "${var.label_prefix}k8sMasterSubnetAD3"
  dns_label                  = "k8smasterad3"
  vcn_id                     = "${oci_core_virtual_network.CompleteVCN.id}"
  route_table_id             = "${oci_core_route_table.MgmtRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CompleteVCN.default_dhcp_options_id}"
  security_list_ids          = ["${concat(list(oci_core_security_list.K8SMasterSubnet.id), var.additional_k8smaster_security_lists_ids)}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "k8sWorkerSubnetAD1" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block                 = "10.0.40.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "${var.label_prefix}k8sWorkerSubnetAD1"
  dns_label                  = "k8sworkerad1"
  vcn_id                     = "${oci_core_virtual_network.CompleteVCN.id}"
  route_table_id             = "${oci_core_route_table.MgmtRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CompleteVCN.default_dhcp_options_id}"
  security_list_ids          = ["${concat(list(oci_core_security_list.K8SWorkerSubnet.id), var.additional_k8sworker_security_lists_ids)}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "k8sWorkerSubnetAD2" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block                 = "10.0.41.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "${var.label_prefix}k8sWorkerSubnetAD2"
  dns_label                  = "k8sworkerad2"
  vcn_id                     = "${oci_core_virtual_network.CompleteVCN.id}"
  route_table_id             = "${oci_core_route_table.MgmtRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CompleteVCN.default_dhcp_options_id}"
  security_list_ids          = ["${concat(list(oci_core_security_list.K8SWorkerSubnet.id), var.additional_k8sworker_security_lists_ids)}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_subnet" "k8sWorkerSubnetAD3" {
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  cidr_block                 = "10.0.42.0/24"
  compartment_id             = "${var.compartment_ocid}"
  display_name               = "${var.label_prefix}k8sWorkerSubnetAD3"
  dns_label                  = "k8sworkerad3"
  vcn_id                     = "${oci_core_virtual_network.CompleteVCN.id}"
  route_table_id             = "${oci_core_route_table.MgmtRouteTable.id}"
  dhcp_options_id            = "${oci_core_virtual_network.CompleteVCN.default_dhcp_options_id}"
  security_list_ids          = ["${concat(list(oci_core_security_list.K8SWorkerSubnet.id), var.additional_k8sworker_security_lists_ids)}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}
