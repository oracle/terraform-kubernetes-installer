variable "availability_domain" {}
variable "cidr_block" {}
variable "display_name" {}
variable "dns_label" {}
variable "vcn_id" {}
variable "route_table_id" {}
variable "compartment_ocid" {}

variable "security_list_id" {
  type = "list"
}

variable "additional_security_lists_ids" {
  type    = "list"
  default = []
}

variable "dhcp_options_id" {}

variable "label_prefix" {
  default = ""
}
