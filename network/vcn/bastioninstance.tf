/**
 * The Bastion instances will be used by instances in private subnets for network security best practices.
 */

resource "oci_core_instance" "BastionInstanceAD1" {
  count               = "${(var.control_plane_subnet_access == "private") && (var.bastion_instance_ad1_enabled == "true") ? "1" : "0"}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.label_prefix}bastion-ad1"
  image               = "${lookup(data.oci_core_images.ImageOCID.images[0], "id")}"
  shape               = "${var.bastion_instance_shape}"

  create_vnic_details {
    subnet_id = "${(var.control_plane_subnet_access == "private") && (var.dedicated_bastion_subnets == "true") ? "${element(concat(oci_core_subnet.BastionSubnetAD1.*.id,list("")),0)}" : "${oci_core_subnet.PublicSubnetAD1.id}"}"
  }

  metadata {
    ssh_authorized_keys = "${var.bastion_instance_ssh_public_key_openssh}"
  }

  timeouts {
    create = "10m"
  }
}

resource "oci_core_instance" "BastionInstanceAD2" {
  count               = "${(var.control_plane_subnet_access == "private") && (var.bastion_instance_ad2_enabled == "true") ? "1" : "0"}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.label_prefix}bastion-ad2"
  image               = "${lookup(data.oci_core_images.ImageOCID.images[0], "id")}"
  shape               = "${var.bastion_instance_shape}"

  create_vnic_details {
    subnet_id = "${(var.control_plane_subnet_access == "private") && (var.dedicated_bastion_subnets == "true") ? "${element(concat(oci_core_subnet.BastionSubnetAD2.*.id,list("")),0)}" : "${oci_core_subnet.PublicSubnetAD2.id}"}"
  }

  metadata {
    ssh_authorized_keys = "${var.bastion_instance_ssh_public_key_openssh}"
  }

  timeouts {
    create = "10m"
  }
}

resource "oci_core_instance" "BastionInstanceAD3" {
  count               = "${(var.control_plane_subnet_access == "private") && (var.bastion_instance_ad3_enabled == "true") ? "1" : "0"}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.label_prefix}bastion-ad3"
  image               = "${lookup(data.oci_core_images.ImageOCID.images[0], "id")}"
  shape               = "${var.bastion_instance_shape}"

  create_vnic_details {
    subnet_id = "${(var.control_plane_subnet_access == "private") && (var.dedicated_bastion_subnets == "true") ? "${element(concat(oci_core_subnet.BastionSubnetAD3.*.id,list("")),0)}" : "${element(concat(oci_core_subnet.PublicSubnetAD3.*.id,list("")),0)}"}"
  }

  metadata {
    ssh_authorized_keys = "${var.bastion_instance_ssh_public_key_openssh}"
  }

  timeouts {
    create = "10m"
  }
}
