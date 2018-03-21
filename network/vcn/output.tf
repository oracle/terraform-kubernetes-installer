output "vcn_id" {
  value = "${oci_core_virtual_network.CompleteVCN.*.id}"
}

output "public_routetable_id" {
  value ="${oci_core_route_table.PublicRouteTable.*.id}"
}

output "dhcp_options_id" {
  value ="${oci_core_virtual_network.CompleteVCN.*.default_dhcp_options_id}"
}

