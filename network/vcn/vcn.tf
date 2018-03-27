resource "oci_core_virtual_network" "CompleteVCN" {
  count          = "${var.create_vcn == "true" ? 1 : 0}"
  cidr_block     = "${var.vcn_cidr}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}${var.vcn_dns_name}"
  dns_label      = "${var.vcn_dns_name}"
}

resource "oci_core_internet_gateway" "PublicIG" {
  count          = "${var.create_vcn == "true" ? 1 : 0}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}PublicIG"
  vcn_id         = "${oci_core_virtual_network.CompleteVCN.id}"
}

resource "oci_core_route_table" "PublicRouteTable" {
  count          = "${var.create_vcn == "true" ? 1 : 0}"
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.CompleteVCN.id}"
  display_name   = "${var.label_prefix}RouteTableForComplete"

  route_rules {
    cidr_block = "0.0.0.0/0"

    # Internet Gateway route target for instances on public subnets
    network_entity_id = "${oci_core_internet_gateway.PublicIG.id}"
  }
}

