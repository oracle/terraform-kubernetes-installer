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
  default = "17.06.2.ol"
}

variable "oracle_linux_image_name" {
  default = "Oracle-Linux-7.4-2018.01.20-0"
}

variable "etcd_ver" {
  default = "v3.2.2"
}

variable "flannel_ver" {
  default = "v0.10.0"
}

variable "ssh_private_key" {}

# Kubernetes
variable "k8s_ver" {
  default = "1.8.5"
}

variable "k8s_dashboard_ver" {
  default = "1.6.3"
}

variable "k8s_dns_ver" {
  default = "1.14.2"
}

variable "api_server_count" {}

variable "root_ca_pem" {}
variable "api_server_private_key_pem" {}
variable "api_server_cert_pem" {}
variable "k8s_apiserver_token_admin" {}

# etcd
variable "etcd_discovery_url" {}
variable "etcd_endpoints" {}

variable "master_docker_max_log_size" {
  description = "Maximum size of the k8s master docker container json logs"
  default = "50m"
}
variable "master_docker_max_log_files" {
  description = "Maximum number of k8s master docker container json logs to rotate"
  default = "5"
}

variable "cloud_controller_secret" {}

variable "flexvolume_driver_secret" {}

variable "volume_provisioner_secret" {}
