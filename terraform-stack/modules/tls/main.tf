# Instance SSH Key Pairs

resource "tls_private_key" "ssh" {
  lifecycle {
    create_before_destroy = true
  }

  count     = "${var.ssh_private_key == "" ? 1 : 0}"
  algorithm = "RSA"
  rsa_bits  = 2048
}
