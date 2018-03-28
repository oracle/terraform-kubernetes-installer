variable "compartment_ocid" {}
variable "tenancy_ocid" {}


variable "vcn" {}

variable "subnet_ad1_id" {}
variable "subnet_ad2_id" {}
variable "subnet_ad3_id" {}

variable "control_plane_subnet_access" {
  description = "Whether instances in the control plane are launched in a public or private subnets"
  default     = "public"
}

variable "domain_name" {}

variable "etcd_ol_image_name" {
  default = "Oracle-Linux-7.4-2018.01.20-0"
}

variable "label_prefix" {
  description = "To create unique identifier for multiple clusters in a compartment."
  type        = "string"
  default     = ""
}

# Load Balancers
variable "etcd_lb_enabled" {
  description = "enable/disable the etcd load balancer. true: use the etcd load balancer ip. false:use a list of etcd instance ips."
  default = "true"
}

variable "etcd_lb_access" {
  description = "Whether etcd load balancer is launched in a public or private subnet"
  default     = "private"
}

variable "etcdLBShape" {
  default = "100Mbps"
}

variable "ssh_public_key_openssh" {
  
}

variable "etcdShape" {
  default = "VM.Standard1.1"
}

variable "docker_config"  {
  type = "map"
  default = {
    max_log_size    = "50m"
    max_log_files   = "5"
  }
}

variable "flannel_config"  {
  type = "map"
  default = {
    backend             = "VXLAN"
    network_cidr        = "10.99.0.0/16"
    network_subnetlen   = 24
  }
}

variable "iscsi_volume_config"  {
  type = "map"
  default = {
    create = false
    size = 50
  }
}

variable "etcdAd1Count" {
  default = 1
}

variable "etcdAd2Count" {
  default = 0
}

variable "etcdAd3Count" {
  default = 0
}

variable "etcd_maintain_private_ip" {
  default = "false"
}

