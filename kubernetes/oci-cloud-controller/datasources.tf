
data "template_file" "oci-cloud-controller-secret" {
  template = "${file("${path.module}/cloud-provider-secret.yaml")}"
  vars = {
    tenancy = "${var.tenancy}"
    region = "${var.region}"
    compartment = "${var.compartment_ocid}"
    
    fingerprint = "${oci_identity_api_key.cloud_controller_key_assoc.fingerprint}"
    user= "${oci_identity_user.cloud_controller_user.id}"
    key = "${jsonencode(tls_private_key.cloud_controller_user_key.private_key_pem)}"
    
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
