data "http" "oci-cloud-controller-manifest" {
  url = "https://raw.githubusercontent.com/oracle/oci-cloud-controller-manager/${var.oci_cloud_controller_manager_version}/manifests/oci-cloud-controller-manager.yaml"
}

data "http" "oci-cloud-controller-rbac" {
  url = "https://raw.githubusercontent.com/oracle/oci-cloud-controller-manager/${var.oci_cloud_controller_manager_version}/manifests/oci-cloud-controller-manager-rbac.yaml"
}

data "template_file" "oci-cloud-controller-secret" {
  template = "${file("${path.module}/cloud-provider-secret.yaml")}"
  vars = {
    tenancy = "${var.tenancy}"
    region = "${var.region}"
    fingerprint = "${var.fingerprint}"
    compartment = "${var.compartment_ocid}"
    user= "${var.user_ocid}"
    key = "${jsonencode(file(var.private_key_path))}"
    subnet1 = "${var.subnet1}"
    subnet2 = "${var.subnet1}"
  }
}

data "template_file" "cloud-provider-yaml" {
  template = "${file("${path.module}/cloud-provider.yaml")}"
  vars = {
    cloud_provider_secret_yaml = "${base64encode(data.template_file.oci-cloud-controller-secret.rendered)}"
  }
}
