
data "template_file" "oci-cloud-controller-secret" {
  template = "${file("${path.module}/cloud-provider-secret.yaml")}"
  vars = {
    tenancy     = "${var.tenancy}"
    region      = "${var.region}"
    compartment = "${var.compartment_ocid}"
    
    # if cloud_controller_user_ocid is empty string then generate a user/group/policy and use it here
    fingerprint = "${var.cloud_controller_user_ocid=="" ? join("", oci_identity_api_key.cloud_controller_key_assoc.*.fingerprint) : var.cloud_controller_user_fingerprint }"
    user        = "${var.cloud_controller_user_ocid=="" ? join("", oci_identity_user.cloud_controller_user.*.id) : var.cloud_controller_user_ocid }"
    key         = "${var.cloud_controller_user_ocid=="" ? jsonencode(join("", tls_private_key.cloud_controller_user_key.*.private_key_pem)) : jsonencode(file(var.cloud_controller_user_private_key_path))}"
    
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
