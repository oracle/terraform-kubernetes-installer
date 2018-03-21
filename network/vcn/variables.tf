variable "vcn_dns_name" {
  default = "k8sbmcs"

}

variable "create_vcn" {

}

variable "vcn_cidr" {
  default = "10.0.0.0/16"
}

variable "compartment_ocid" {}

variable "label_prefix" {}
