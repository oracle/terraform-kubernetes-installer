# Gets the OCID of the OS image to use
data "oci_core_images" "ImageOCID" {
  compartment_id           = "${var.compartment_ocid}"
  operating_system         = "Oracle Linux"
  operating_system_version = "${var.instance_os_ver}"
}

# Cloud call to get a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

# "cloud init" file to bootstrap instance
data "template_file" "etcd-bootstrap" {
  template = "${file("${path.module}/cloud_init/bootstrap.template.sh")}"

  vars {
    domain_name               = "${var.domain_name}"
    docker_ver                = "${var.docker_ver}"
    etcd_ver                  = "${var.etcd_ver}"
    flannel_network_cidr      = "${var.flannel_network_cidr}"
    flannel_network_subnetlen = "${var.flannel_network_subnetlen}"
    flannel_backend           = "${var.flannel_backend}"
    etcd_discovery_url        = "${file("${path.root}/generated/discovery${var.etcd_discovery_url}")}"
  }
}
