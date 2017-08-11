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
variable "shape" {}
variable "tenancy_ocid" {}

variable "label_prefix" {
  default = ""
}

# Instance
variable "ssh_public_key_openssh" {}

variable "docker_ver" {
  default = "17.03.1.ce"
}

variable "instance_os_ver" {
  default = "7.4"
}

variable "etcd_ver" {
  default = "v3.2.2"
}

variable "flannel_ver" {
  default = "v0.7.1"
}

# Kubernetes
variable "k8s_ver" {
  default = "1.7.4"
}

variable "k8s_dashboard_ver" {
  default = "1.6.3"
}

variable "k8s_dns_ver" {
  default = "1.14.2"
}

variable "api_server_count" {}
variable "etcd_lb" {}
variable "root_ca_pem" {}
variable "api_server_private_key_pem" {}
variable "api_server_cert_pem" {}
variable "k8s_apiserver_token_admin" {}

# etcd
variable "etcd_discovery_url" {}
