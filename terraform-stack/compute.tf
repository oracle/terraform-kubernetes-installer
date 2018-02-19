### Compute instances

resource "baremetal_core_instance" "logging-instance" {
  count               = "1"
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ADs.availability_domains[var.logging-instance-ad - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.label_prefix}logging-${var.logging-instance-ad}001"
  hostname_label      = "logging-${var.logging-instance-ad}001"
  image               = "${var.os_image_ocid == "" ? lookup(data.baremetal_core_images.OracleLinuxImageOCID.images[0], "id") : var.os_image_ocid}"
  shape               = "${var.loggingShape}"
  subnet_id           = "${module.subnet-logging-1.id}"

  extended_metadata {
    ssh_authorized_keys = "${module.tls.ssh_public_key_openssh}"
    tags                = "group:logging"
  }

  timeouts {
    create = "60m"
  }
}

resource "null_resource" "remote-exec-logging" {
  count = "1"

  provisioner "remote-exec" {
    connection {
      agent       = false
      timeout     = "600s"
      host        = "${element(baremetal_core_instance.logging-instance.*.public_ip, count.index)}"
      user        = "opc"
      private_key = "${module.tls.ssh_private_key}"
    }
  }
}

resource "baremetal_core_instance" "monitoring-instance" {
  count               = "1"
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ADs.availability_domains[var.monitoring-instance-ad - 1],"name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.label_prefix}monitoring-${var.monitoring-instance-ad}001"
  hostname_label      = "monitoring-${var.monitoring-instance-ad}001"
  image               = "${var.os_image_ocid == "" ? lookup(data.baremetal_core_images.OracleLinuxImageOCID.images[0], "id") : var.os_image_ocid}"
  shape               = "${var.monitoringShape}"
  subnet_id           = "${module.subnet-monitoring-1.id}"

  extended_metadata {
    ssh_authorized_keys = "${module.tls.ssh_public_key_openssh}"
    tags                = "group:monitoring"
  }

  timeouts {
    create = "60m"
  }
}

resource "null_resource" "remote-exec-monitoring" {
  count = "1"

  provisioner "remote-exec" {
    connection {
      agent       = false
      timeout     = "600s"
      host        = "${element(baremetal_core_instance.monitoring-instance.*.public_ip, count.index)}"
      user        = "opc"
      private_key = "${module.tls.ssh_private_key}"
    }
  }
}