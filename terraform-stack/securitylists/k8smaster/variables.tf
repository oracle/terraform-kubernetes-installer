variable "compartment_ocid" {}
variable "vcn_id" {}

variable "label_prefix" {
  default = ""
}

variable "bmc_ingress_cidrs" {
  type = "map"

  default = {
    LBAAS-PHOENIX-1-CIDR = "129.144.0.0/12"
    LBAAS-ASHBURN-1-CIDR = "129.213.0.0/16"
    VCN-CIDR             = "10.0.0.0/16"
  }
}

variable "default_ssh_ingress_cidr" {
  default = "10.0.0.0/16"
}

variable "default_https_ingress_cidr" {
  default = "10.0.0.0/16"
}
