resource "tls_private_key" "cloud_controller_user_key" {
  count = "${var.cloud_controller_user_ocid==""? 1 : 0 }"
  algorithm   = "RSA"
  rsa_bits = 2048
}

resource "oci_identity_group" "cloud_controller_group" {
  count = "${var.cloud_controller_user_ocid==""? 1 : 0 }"
  name = "${var.label_prefix}cloud_controller_group"
  description = "Terraform created group for OCI Cloud controller manager"
}

resource "oci_identity_user" "cloud_controller_user" {
  count = "${var.cloud_controller_user_ocid==""? 1 : 0 }"
  name = "${var.label_prefix}cloud_controller_user"
  description = "Terraform created user for OCI Cloud controller manager"
}

resource "oci_identity_api_key" "cloud_controller_key_assoc" {
  count = "${var.cloud_controller_user_ocid==""? 1 : 0 }"
  user_id = "${oci_identity_user.cloud_controller_user.id}"
  key_value = "${tls_private_key.cloud_controller_user_key.public_key_pem}"
}

resource "oci_identity_user_group_membership" "cloud_controller_user_group_assoc" {
  count = "${var.cloud_controller_user_ocid==""? 1 : 0 }"
  compartment_id = "${var.tenancy}"
  user_id = "${oci_identity_user.cloud_controller_user.id}"
  group_id = "${oci_identity_group.cloud_controller_group.id}"
}

resource "oci_identity_policy" "cloud_controller_policy" {
  count = "${var.cloud_controller_user_ocid==""? 1 : 0 }"
  depends_on = ["oci_identity_group.cloud_controller_group"]
  compartment_id = "${var.compartment_ocid}"
  name = "${var.label_prefix}cloud_controller_policy"
  description = "${var.label_prefix}cloud_controller_group policy"
  statements = [
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to manage load-balancers in compartment id ${var.compartment_ocid}",
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to use security-lists in compartment id ${var.compartment_ocid}",
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to read instances in compartment id ${var.compartment_ocid}",
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to read subnets in compartment id ${var.compartment_ocid}",
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to read vnics in compartment id ${var.compartment_ocid}",
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to read vnic-attachments in compartment id ${var.compartment_ocid}",
  ]
}
