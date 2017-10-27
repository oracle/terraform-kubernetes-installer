/**
 * The NAT instance will be used by instances in private subnets for all outbound traffic.
 */

# TODO consider adding support for a NAT instance per AD.

resource "oci_core_instance" "NATInstance" {
  count               = "${var.network_access == "private" ? "1" : "0"}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.nat_instance_availability_domain - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.label_prefix}nat-ad${var.nat_instance_availability_domain}"
  image               = "${lookup(data.oci_core_images.ImageOCID.images[0], "id")}"
  shape               = "${var.nat_instance_shape}"

  create_vnic_details {
    # Terraform does not allow for interpolation in resource names e.g. AD${var.nat_instance_availability_domain}
    subnet_id = "${oci_core_subnet.PublicSubnetAD1.id}"

    # Skip the source/destination check so that the VNIC will forward traffic.
    skip_source_dest_check = true
  }

  metadata {
    ssh_authorized_keys = "${var.nat_instance_ssh_public_key_openssh}"

    # Automate NAT instance configuration with cloud init run at launch
    user_data = "${base64encode(file("${path.module}/cloud_init/bootstrap.template.yaml"))}"
  }

  timeouts {
    create = "10m"
  }
}
