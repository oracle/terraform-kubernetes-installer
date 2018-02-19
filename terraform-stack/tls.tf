### SSH keypairs, CA, and Certificates

module "tls" {
  source                 = "./modules/tls/"
  ssh_private_key        = "${var.ssh_private_key}"
  ssh_public_key_openssh = "${var.ssh_public_key_openssh}"
}
