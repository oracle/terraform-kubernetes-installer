variable "compartment_ocid" {}
variable "vcn_dns_name" {}

variable "ingress_cidrs" {
  type = "map"

  default = {
    VPC-CIDR = "10.0.0.0/16"
  }
}

resource "baremetal_core_virtual_network" "CompleteVCN" {
  cidr_block     = "${lookup(var.ingress_cidrs, "VPC-CIDR")}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}${var.vcn_dns_name}"
  dns_label      = "${var.vcn_dns_name}"
}

resource "baremetal_core_internet_gateway" "CompleteIG" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}CompleteIG"
  vcn_id         = "${baremetal_core_virtual_network.CompleteVCN.id}"
}

resource "baremetal_core_route_table" "RouteForComplete" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${baremetal_core_virtual_network.CompleteVCN.id}"
  display_name   = "${var.label_prefix}RouteTableForComplete"

  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = "${baremetal_core_internet_gateway.CompleteIG.id}"
  }
}

output "id" {
  value = "${baremetal_core_virtual_network.CompleteVCN.id}"
}

output "route_for_complete_id" {
  value = "${baremetal_core_route_table.RouteForComplete.id}"
}

output "dhcp_options_id" {
  value = "${baremetal_core_virtual_network.CompleteVCN.default_dhcp_options_id}"
}
