variable "availability_domain" {}
variable "compartment_ocid" {}
variable "display_name" {}
variable "hostname_label" {}

variable "shape" {
  default = "VM.Standard1.1"
}

variable "subnet_id" {}
variable "ssh_public_key_openssh" {}
variable "domain_name" {}

variable "label_prefix" {
  default = ""
}

variable "docker_ver" {
  default = "17.06.2.ol"
}

variable "oracle_linux_image_name" {
  default = "Oracle-Linux-7.4-2017.10.25-0"
}

variable "etcd_ver" {
  default = "v3.2.2"
}

variable "tenancy_ocid" {}
variable "flannel_network_cidr" {}
variable "flannel_network_subnetlen" {}
variable "flannel_backend" {}
variable "etcd_discovery_url" {}

variable "count" {
  default = "1"
}

variable "etcd_docker_max_log_size" {
  description = "Maximum size of the etcd docker container json logs"
  default = "50m"
}
variable "etcd_docker_max_log_files" {
  description = "Maximum number of etcd docker container json logs to rotate"
  default = "5"
}

