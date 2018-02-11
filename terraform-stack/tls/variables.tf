variable "ssh_private_key" {
  description = "SSH private key for instances (generated if left blank)"
  default     = ""
}

variable "ssh_public_key_openssh" {
  description = "SSH public key in OpenSSH authorized_keys format for instances (generated if left blank)"
  default     = ""
}