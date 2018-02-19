# BMCS
variable "availability_domain" {}

variable "compartment_ocid" {}
variable "display_name_prefix" {}
variable "hostname_label_prefix" {}

variable "count" {
  default = "1"
}

variable "control_plane_subnet_access" {
  description = "Whether instances in the control plane are launched in a public or private subnets"
  default     = "public"
}

variable "network_cidrs" {
  type = "map"
}
variable "subnet_id" {}
variable "subnet_name" {}
variable "domain_name" {}
variable "shape" {}
variable "tenancy_ocid" {}

variable "label_prefix" {
  default = ""
}

# Instance
variable "ssh_public_key_openssh" {}

variable "oracle_linux_image_name" {
  default = "Oracle-Linux-7.4-2018.01.20-0"
}

variable "ssh_private_key" {}

variable "assign_private_ip" {
  description = "Assign a static private ip based on CIDR block for that AD"
  default = false
}
