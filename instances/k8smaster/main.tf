/**
 * The instances/k8smaster module provisions and configures one or more Kubernetes Master instances.
 */

resource "baremetal_core_instance" "TFInstanceK8sMaster" {
  count               = "${var.count}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.label_prefix}${var.display_name_prefix}-${count.index}"
  hostname_label      = "${var.hostname_label_prefix}-${count.index}"
  image               = "${lookup(data.baremetal_core_images.ImageOCID.images[0], "id")}"
  shape               = "${var.shape}"
  subnet_id           = "${var.subnet_id}"

  metadata {
    roles               = "masters"
    ssh_authorized_keys = "${var.ssh_public_key_openssh}"
    user_data           = "${data.template_cloudinit_config.master.rendered}"
  }

  timeouts {
    create = "60m"
  }
}
