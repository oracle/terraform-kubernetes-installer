variable "availability_domain" {}
variable "compartment_ocid" {}
variable "display_name" {}
variable "hostname_label" {}

variable "shape" {
  default = "VM.Standard1.1"
}

variable "subnet_id" {}
variable "ssh_public_key_openssh" {}
variable "ssh_private_key" {}
variable "domain_name" {}

variable "label_prefix" {
  default = ""
}

variable "instance_os" {
  default = "Oracle Linux"
}

variable "instance_os_ver" {
  default = "7.4"
}

variable "tenancy_ocid" {}

variable "count" {
  default = "1"
}
