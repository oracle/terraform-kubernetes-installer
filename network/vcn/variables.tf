variable "network_cidrs" {
  type = "map"

  default = {
    VCN-CIDR          = "10.0.0.0/16"
    PublicSubnetAD1   = "10.0.10.0/24"
    PublicSubnetAD2   = "10.0.11.0/24"
    PublicSubnetAD3   = "10.0.12.0/24"
    natSubnetAD1      = "10.0.13.0/24"
    natSubnetAD2      = "10.0.14.0/24"
    natSubnetAD3      = "10.0.15.0/24"
    bastionSubnetAD1  = "10.0.16.0/24"
    bastionSubnetAD2  = "10.0.17.0/24"
    bastionSubnetAD3  = "10.0.18.0/24"
    etcdSubnetAD1     = "10.0.20.0/24"
    etcdSubnetAD2     = "10.0.21.0/24"
    etcdSubnetAD3     = "10.0.22.0/24"
    masterSubnetAD1   = "10.0.30.0/24"
    masterSubnetAD2   = "10.0.31.0/24"
    masterSubnetAD3   = "10.0.32.0/24"
    workerSubnetAD1   = "10.0.40.0/24"
    workerSubnetAD2   = "10.0.41.0/24"
    workerSubnetAD3   = "10.0.42.0/24"
    k8sCCMLBSubnetAD1 = "10.0.50.0/24"
    k8sCCMLBSubnetAD2 = "10.0.51.0/24"
    k8sCCMLBSubnetAD3 = "10.0.52.0/24"
  }
}

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

variable "additional_nat_security_lists_ids" {
  type    = "list"
  default = []
}

variable "additional_bastion_security_lists_ids" {
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

variable "master_nodeport_ingress" {
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

variable "external_icmp_ingress" {
  description = "A CIDR notation IP range that is allowed to ICMP to instances on all the subnets"
  default = "0.0.0.0/0"
}

variable "internal_icmp_ingress" {
  description = "A CIDR notation IP range that is allowed to ICMP to instances on all the subnets"
  default     = "10.0.0.0/16"
}

variable "nat_instance_ssh_public_key_openssh" {}

variable "nat_instance_oracle_linux_image_name" {
  default = "Oracle-Linux-7.4-2018.01.20-0"
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

variable dedicated_nat_subnets {
  default = "false"
}

variable "bastion_instance_ssh_public_key_openssh" {}

variable "bastion_instance_oracle_linux_image_name" {
  default = "Oracle-Linux-7.4-2018.01.10-0"
}

variable "bastion_instance_shape" {
  default = "VM.Standard1.2"
}

variable bastion_instance_ad1_enabled {
  default = "false"
}

variable bastion_instance_ad2_enabled {
  default = "true"
}

variable bastion_instance_ad3_enabled {
  default = "false"
}

variable dedicated_bastion_subnets {
  default = "false"
}
