output "cloud_controller_user" {
  sensitive = true
  value = "${oci_identity_group.cloud_controller_group.id}"
}

output "cloud_controller_public_key" {
  value = "${tls_private_key.cloud_controller_user_key.public_key_pem}"
}

output "cloud_controller_private_key" {
  sensitive = true
  value = "${tls_private_key.cloud_controller_user_key.private_key_pem}"
}

output "cloud_controller_user_fingerprint" {
  value = "run 'terraform output cloud_controller_private_key > cc_key && openssl rsa -in cc_key -pubout -outform DER | openssl md5 -c && rm cc_key' determine the fingerprint"
}