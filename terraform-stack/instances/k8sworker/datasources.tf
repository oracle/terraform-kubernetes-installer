# Prevent oci_core_images image list from changing underneath us.
data "oci_core_images" "ImageOCID" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.oracle_linux_image_name}"
}

# Cloud call to get a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

data "template_file" "setup-template" {
  template = "${file("${path.module}/scripts/setup.template.sh")}"

  vars = {
    worker_iscsi_volume_mount = "${var.worker_iscsi_volume_mount}"
  }
}

data "template_file" "setup-preflight" {
  template = "${file("${path.module}/scripts/setup.preflight.sh")}"

  vars = {
  }
}


data "template_file" "kube_worker_cloud_init_file" {
  template = "${file("${path.module}/cloud_init/bootstrap.template.yaml")}"
  vars = {
    setup_preflight_sh_content         = "${base64gzip(data.template_file.setup-preflight.rendered)}"
    setup_template_sh_content          = "${base64gzip(data.template_file.setup-template.rendered)}"
  }
}

data "template_cloudinit_config" "master" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "bootstrap.yaml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.kube_worker_cloud_init_file.rendered}"
  }
}
