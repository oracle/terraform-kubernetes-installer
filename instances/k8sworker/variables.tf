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

variable "docker_ver" {
  default = "17.03.1.ce"
}

variable "instance_os_ver" {
  default = "7.4"
}

variable "etcd_lb" {}

variable "etcd_ver" {
  default = "v3.2.2"
}

# TODO - because the bootstrap template uses yum, we only support OEL7
variable "flannel_ver" {
  default = "v0.7.1"
}

# Kubernetes
variable "master_lb" {}

variable "k8s_ver" {
  default = "1.7.4"
}

variable "root_ca_pem" {}
variable "root_ca_key" {}
variable "api_server_private_key_pem" {}
variable "api_server_cert_pem" {}

# etcd
variable "etcd_discovery_url" {}
