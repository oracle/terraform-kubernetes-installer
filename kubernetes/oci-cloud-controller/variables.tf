

variable "oci_cloud_controller_manager_version" {
  default = "master"
}

variable "compartment_ocid" {}
variable "region" {}
variable "tenancy" {}
variable "subnet1" {}
variable "subnet2" {}

variable "label_prefix" {
  description = "To create unique identifier for multiple clusters in a compartment."
  type        = "string"
}
