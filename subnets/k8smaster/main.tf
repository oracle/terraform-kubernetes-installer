resource "oci_core_subnet" "k8sMasterSubnet" {
  availability_domain = "${var.availability_domain}"
  cidr_block          = "${var.cidr_block}"
  display_name        = "${var.label_prefix}${var.display_name}"
  dns_label           = "${var.dns_label}"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${var.vcn_id}"
  route_table_id      = "${var.route_table_id}"
  dhcp_options_id     = "${var.dhcp_options_id}"
  security_list_ids   = ["${concat(var.security_list_id, var.additional_security_lists_ids)}"]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}
