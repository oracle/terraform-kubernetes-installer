variable "tenancy_ocid" {}

variable "additional_etcd_security_lists_ids" {
  type    = "list"
  default = []
}

variable "additional_k8smaster_security_lists_ids" {
  type    = "list"
  default = []
}

variable "additional_k8sworker_security_lists_ids" {
  type    = "list"
  default = []
}

# VCN

variable "label_prefix" {
  type    = "string"
  default = ""
}

variable "compartment_ocid" {}
variable "vcn_dns_name" {}

variable "ingress_cidrs" {
  type = "map"

  default = {
    VPC-CIDR = "10.0.0.0/16"
  }
}

# Security lists

variable "bmc_ingress_cidrs" {
  type = "map"

  default = {
    LBAAS-PHOENIX-1-CIDR = "129.144.0.0/12"
    LBAAS-ASHBURN-1-CIDR = "129.213.0.0/16"
    VCN-CIDR             = "10.0.0.0/16"
  }
}

variable "etcd_ssh_ingress" {
  default = "10.0.0.0/16"
}

variable "etcd_cluster_ingress" {
  default = "10.0.0.0/16"
}

variable "master_ssh_ingress" {
  default = "10.0.0.0/16"
}

variable "master_https_ingress" {
  default = "10.0.0.0/16"
}

variable "worker_ssh_ingress" {
  default = "10.0.0.0/16"
}

variable "worker_nodeport_ingress" {
  default = "10.0.0.0/16"
}
