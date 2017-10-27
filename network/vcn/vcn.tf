resource "oci_core_virtual_network" "CompleteVCN" {
  cidr_block     = "${lookup(var.ingress_cidrs, "VPC-CIDR")}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}${var.vcn_dns_name}"
  dns_label      = "${var.vcn_dns_name}"
}

resource "oci_core_internet_gateway" "PublicIG" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}PublicIG"
  vcn_id         = "${oci_core_virtual_network.CompleteVCN.id}"
}

resource "oci_core_route_table" "PublicRouteTable" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.CompleteVCN.id}"
  display_name   = "${var.label_prefix}RouteTableForComplete"

  route_rules {
    cidr_block = "0.0.0.0/0"

    # Internet Gateway route target for instances on public subnets
    network_entity_id = "${oci_core_internet_gateway.PublicIG.id}"
  }
}

resource "oci_core_route_table" "PrivateIPRouteTable" {
  # Provisioned only when k8s instances are in private subnets
  count          = "${var.network_access == "private" ? "1" : "0"}"
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.CompleteVCN.id}"
  display_name   = "PrivateIPRouteTableAD${var.nat_instance_availability_domain}"

  route_rules {
    # All traffic leaving the subnet needs to go to route target.
    cidr_block = "0.0.0.0/0"

    # Private IP route target for instances on private subnets
    network_entity_id = "${element(data.oci_core_private_ips.privateIpDatasource.private_ips.0.id, count.index)}"
  }
}
