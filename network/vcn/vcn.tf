resource "oci_core_virtual_network" "CompleteVCN" {
  cidr_block     = "${lookup(var.ingress_cidrs, "VPC-CIDR")}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}${var.vcn_dns_name}"
  dns_label      = "${var.vcn_dns_name}"
}

resource "oci_core_internet_gateway" "MgmtIG" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}MgmtIG"
  vcn_id         = "${oci_core_virtual_network.CompleteVCN.id}"
}

resource "oci_core_route_table" "MgmtRouteTable" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.CompleteVCN.id}"
  display_name   = "${var.label_prefix}RouteTableForComplete"

  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.MgmtIG.id}"
  }
}
