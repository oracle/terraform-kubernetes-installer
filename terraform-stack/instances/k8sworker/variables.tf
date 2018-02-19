# BMCS
variable "availability_domain" {}

variable "compartment_ocid" {}
variable "display_name_prefix" {}
variable "hostname_label_prefix" {}

variable "count" {
  default = "1"
}

variable "subnet_id" {}
variable "domain_name" {}
variable "region" {}
variable "shape" {}
variable "tenancy_ocid" {}

variable "label_prefix" {
  default = ""
}

# Instance
variable "ssh_public_key_openssh" {}

variable "ssh_private_key" {}

variable "oracle_linux_image_name" {
  default = "Oracle-Linux-7.4-2018.01.20-0"
}

# iSCSI
variable "worker_iscsi_volume_create" {
  description = "Bool if an iscsi volume should be attached and mounted at /var/lib/docker"
  default = false
}

variable "worker_iscsi_volume_size" {
  description = "Size of iscsi volume to be created"
  default = 50
}

variable "worker_iscsi_volume_mount" {
  description = "Mount point of iscsi volume"
  default = "/var/lib/docker"
}