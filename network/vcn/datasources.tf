# Gets a list of availability domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

# Gets the OCID of the OS image to use for the NAT instance
data "oci_core_images" "ImageOCID" {
  compartment_id           = "${var.compartment_ocid}"
  operating_system         = "Oracle Linux"
  operating_system_version = "${var.nat_instance_os_ver}"
}

# Gets a list of VNIC attachments on the NAT instance
data "oci_core_vnic_attachments" "NATInstanceVnics" {
  count               = "${var.network_access == "private" ? "1" : "0"}"
  compartment_id      = "${var.compartment_ocid}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.nat_instance_availability_domain - 1],"name")}"
  instance_id         = "${oci_core_instance.NATInstance.id}"
}

# Gets the OCID of the first (default) VNIC on the NAT instance
data "oci_core_vnic" "NATInstanceVnic" {
  count   = "${var.network_access == "private" ? "1" : "0"}"
  vnic_id = "${lookup(data.oci_core_vnic_attachments.NATInstanceVnics.vnic_attachments[var.nat_instance_availability_domain - 1],"vnic_id")}"
}

# List Private IPs on the NAT instance
data "oci_core_private_ips" "privateIpDatasource" {
  count   = "${var.network_access == "private" ? "1" : "0"}"
  vnic_id = "${data.oci_core_vnic.NATInstanceVnic.id}"
}
