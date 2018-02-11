# Instance SSH Key Pairs
resource "tls_private_key" "ssh" {
  lifecycle {
    create_before_destroy = true
  }

  algorithm = "RSA"
  count     = "${var.ssh_private_key == "" ? 1 : 0}"
  rsa_bits  = 2048
}
