variable "network_cidrs" {
  type = "map"
  default = {
    VCN-CIDR          = "10.0.0.0/16"
    PublicSubnetAD1   = "10.0.10.0/24"
    PublicSubnetAD2   = "10.0.11.0/24"
    PublicSubnetAD3   = "10.0.12.0/24"
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
variable "availability_domain" {}
variable "compartment_ocid" {}
variable "display_name" {}
variable "hostname_label" {}

variable "shape" {
  default = "VM.Standard1.1"
}

variable "subnet_id" {}
variable "subnet_name" {}
variable "ssh_public_key_openssh" {}
variable "domain_name" {}

variable "label_prefix" {
  default = ""
}

variable "docker_ver" {
  default = "17.06.2.ol"
}

variable "oracle_linux_image_name" {
  default = "Oracle-Linux-7.4-2018.01.10-0"
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

variable "control_plane_subnet_access" {
  description = "Whether instances in the control plane are launched in a public or private subnets"
  default     = "public"
}

variable "etcd_docker_max_log_size" {
  description = "Maximum size of the etcd docker container json logs"
  default = "50m"
}
variable "etcd_docker_max_log_files" {
  description = "Maximum number of etcd docker container json logs to rotate"
  default = "5"
}

# iSCSI
variable "etcd_iscsi_volume_create" {
  description = "Bool if an iscsi volume should be attached and mounted at the etcd volume mount point /etcd"
  default = false
}

variable "etcd_iscsi_volume_size" {
  description = "Size of iscsi volume to be created"
  default = 50
}

variable "assign_private_ip" {
  description = "Assign a static private ip based on CIDR block for that AD"
  default = false
}
