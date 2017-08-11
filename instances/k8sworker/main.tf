/**
 * The instances/k8sworker module provisions and configures one or more Kubernetes Worker instances.
 */

resource "oci_core_instance" "TFInstanceK8sWorker" {
  count               = "${var.count}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.label_prefix}${var.display_name_prefix}-${count.index}"
  hostname_label      = "${var.hostname_label_prefix}-${count.index}"
  image               = "${lookup(data.oci_core_images.ImageOCID.images[0], "id")}"
  shape               = "${var.shape}"
  subnet_id           = "${var.subnet_id}"

  extended_metadata {
    roles               = "nodes"
    ssh_authorized_keys = "${var.ssh_public_key_openssh}"
    user_data           = "${data.template_cloudinit_config.master.rendered}"
    tags = "group:k8s-worker"
  }

  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "nodeName=`getent hosts $(ip route get 1 | awk '{print $NF;exit}') | awk '{print $2}'`",
      "[ -e /usr/bin/kubectl ] && sudo kubectl --kubeconfig /etc/kubernetes/manifests/worker-kubeconfig.yaml drain $nodeName --force",
      "[ -e /usr/bin/kubectl ] && sudo kubectl --kubeconfig /etc/kubernetes/manifests/worker-kubeconfig.yaml delete node $nodeName",
      "exit 0",
    ]

    on_failure = "continue"

    connection {
      host        = "${self.public_ip}"
      user        = "opc"
      private_key = "${var.ssh_private_key}"
      agent       = false
      timeout     = "30s"
    }
  }

  timeouts {
    create = "60m"
  }
}
