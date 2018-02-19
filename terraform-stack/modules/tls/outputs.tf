output "ssh_private_key" {
  value = "${var.ssh_private_key == "" ? join(" ", tls_private_key.ssh.*.private_key_pem) : var.ssh_private_key}"
}

output "ssh_public_key_openssh" {
  value = "${var.ssh_public_key_openssh == "" ? join(" ", tls_private_key.ssh.*.public_key_openssh) : var.ssh_public_key_openssh}"
}
