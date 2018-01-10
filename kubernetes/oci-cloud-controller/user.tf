resource "tls_private_key" "cloud_controller_user_key" {
  algorithm   = "RSA"
  rsa_bits = 2048
}

resource "oci_identity_group" "cloud_controller_group" {
    name = "${var.label_prefix}cloud_controller_group"
    description = "Terraform created group for ocii cloud controller"
}

resource "oci_identity_user" "cloud_controller_user" {
  name = "${var.label_prefix}cloud_controller_user"
  description = "Terraform created user for ocii cloud controller"
}

resource "oci_identity_api_key" "cloud_controller_key_assoc" {
  user_id = "${oci_identity_user.cloud_controller_user.id}"
  key_value = "${tls_private_key.cloud_controller_user_key.public_key_pem}"
}

resource "oci_identity_user_group_membership" "cloud_controller_user_group_assoc" {
  compartment_id = "${var.tenancy}"
  user_id = "${oci_identity_user.cloud_controller_user.id}"
  group_id = "${oci_identity_group.cloud_controller_group.id}"
}

resource "oci_identity_policy" "cloud_controller_policy" {
  depends_on = ["oci_identity_group.cloud_controller_group"]
  compartment_id = "${var.tenancy}"
  name = "${var.label_prefix}cloud_controller_policy"
  description = "${var.label_prefix}cloud_controller_group policy"
  statements = [
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to manage load-balancers in tenancy", #Restrict to compartment?
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to use security-lists in tenancy",
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to read instances in tenancy",
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to read subnets in tenancy",
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to read vnics in tenancy",
    "Allow group id ${oci_identity_group.cloud_controller_group.id} to read vnic-attachments in tenancy",
  ]
}




