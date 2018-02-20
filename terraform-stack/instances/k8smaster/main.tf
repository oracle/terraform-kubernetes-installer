/**
 * The instances/k8smaster module provisions and configures one or more Kubernetes Master instances.
 */

resource "oci_core_instance" "TFInstanceK8sMaster" {
  count               = "${var.count}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.label_prefix}${var.display_name_prefix}-${count.index}"
  hostname_label      = "${var.hostname_label_prefix}-${count.index}"
  image               = "${lookup(data.oci_core_images.ImageOCID.images[0], "id")}"
  shape               = "${var.shape}"

  create_vnic_details {
    subnet_id        = "${var.subnet_id}"
    display_name     = "${var.label_prefix}${var.display_name_prefix}-${count.index}"
    hostname_label   = "${var.hostname_label_prefix}-${count.index}"
    assign_public_ip = "${(var.control_plane_subnet_access == "private") ? "false" : "true"}"
    private_ip       = "${var.assign_private_ip == "true" ? cidrhost(lookup(var.network_cidrs,var.subnet_name), count.index+2) : ""}"
  }

  extended_metadata {
    roles               = "masters"
    ssh_authorized_keys = "${var.ssh_public_key_openssh}"
    tags      = "group:k8s-master"
  }

  timeouts {
    create = "60m"
  }
}
