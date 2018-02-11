output "root_ca_pem" {
  value = "${var.ca_cert == "" ? join(" ", tls_self_signed_cert.root-ca.*.cert_pem) : var.ca_cert}"
}

output "root_ca_key" {
  value = "${var.ca_key == "" ? join(" ", tls_private_key.root-ca.*.private_key_pem) : var.ca_key}"
}

output "api_server_private_key_pem" {
  value = "${var.api_server_private_key == "" ? join(" ", tls_private_key.api-server.*.private_key_pem) : var.api_server_private_key}"
}

output "api_server_cert_pem" {
  value = "${var.api_server_cert == "" ? join(" ", tls_locally_signed_cert.api-server.*.cert_pem) : var.api_server_cert}"
}
