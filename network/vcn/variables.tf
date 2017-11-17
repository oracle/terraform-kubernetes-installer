variable "tenancy_ocid" {}

variable "control_plane_subnet_access" {
  default = "public"
}

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

variable "additional_public_security_lists_ids" {
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

# For optional NAT instance (when control_plane_subnet_access = "private")

variable "public_subnet_ssh_ingress" {
  default = "0.0.0.0/0"
}

variable "public_subnet_http_ingress" {
  default = "0.0.0.0/0"
}

variable "public_subnet_https_ingress" {
  default = "0.0.0.0/0"
}

variable "nat_instance_ssh_public_key_openssh" {}

variable "nat_instance_oracle_linux_image_name" {
  default = "Oracle-Linux-7.4-2017.10.25-0"
}

variable "nat_instance_shape" {
  default = "VM.Standard1.2"
}

variable nat_instance_ad1_enabled {
  default = "false"
}

variable nat_instance_ad2_enabled {
  default = "true"
}

variable nat_instance_ad3_enabled {
  default = "false"
}
