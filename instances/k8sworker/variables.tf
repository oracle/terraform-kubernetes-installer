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
  default = "17.06.2.ol"
}

variable "oracle_linux_image_name" {
  default = "Oracle-Linux-7.4-2018.01.20-0"
}

variable "etcd_ver" {
  default = "v3.2.2"
}

# TODO - because the bootstrap template uses yum, we only support Oracle Linux 7
variable "flannel_ver" {
  default = "v0.9.1"
}

# Kubernetes
variable "master_lb" {}

variable "k8s_ver" {
  default = "1.8.5"
}

variable "root_ca_pem" {}
variable "root_ca_key" {}
variable "api_server_private_key_pem" {}
variable "api_server_cert_pem" {}

# etcd
variable "etcd_discovery_url" {}
variable "etcd_endpoints" {}

variable "worker_docker_max_log_size" {
  description = "Maximum size of the k8s worker docker container json logs"
  default = "50m"
}
variable "worker_docker_max_log_files" {
  description = "Maximum number of the k8s worker docker container json logs to rotate"
  default = "5"
}

# iSCSI
variable "worker_iscsi_volume_create" {
  description = "Bool if an iscsi volume should be attached and mounted at /var/lib/docker"
  default = false
}

variable "worker_iscsi_volume_size" {
  description = "Size of iscsi volume to be created"
  default = 50
}

variable "worker_iscsi_volume_mount" {
  description = "Mount point of iscsi volume"
  default = "/var/lib/docker"
}

variable "flexvolume_driver_version" {}

variable "reverse_proxy_setup" {}

variable "reverse_proxy_clount_init" {}

variable "generic_image_ocid" {
  default = "ocid1.image.oc1.iad.aaaaaaaautkmgjebjmwym5i6lvlpqfzlzagvg5szedggdrbp6rcjcso3e4kq"
}
