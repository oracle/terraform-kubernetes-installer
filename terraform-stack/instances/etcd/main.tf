/**
 * The instances/etcd module provisions and configures one or more etcd instances.
 */

resource "baremetal_core_instance" "TFInstanceEtcd" {
  count               = "${var.count}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.label_prefix}${var.display_name}-${count.index}"
  hostname_label      = "${var.hostname_label}-${count.index}"
  image               = "${lookup(data.baremetal_core_images.ImageOCID.images[0], "id")}"
  shape               = "${var.shape}"
  subnet_id           = "${var.subnet_id}"

  extended_metadata {
    ssh_authorized_keys = "${var.ssh_public_key_openssh}"
    tags = "group:etcd"
  }

  timeouts {
    create = "60m"
  }
}

resource "null_resource" "remote-exec-etcd" {
  count = "${var.count}"

  provisioner "remote-exec" {
    connection {
      agent       = false
      timeout     = "600s"
      host        = "${element(baremetal_core_instance.TFInstanceEtcd.*.public_ip, count.index)}"
      user        = "opc"
      private_key = "${var.ssh_private_key}"
    }
  }
}

resource "null_resource" "remote-exec-k8s-etcd" {
  count = "${var.count}"

  provisioner "remote-exec" {
    connection {
      agent       = false
      timeout     = "600s"
      host        = "${element(baremetal_core_instance.TFInstanceEtcd.*.public_ip, count.index)}"
      user        = "opc"
      private_key = "${var.ssh_private_key}"
    }
  }
}
