# BMCS Service
variable "tenancy_ocid" {}

variable "compartment_ocid" {}

variable "domain_name" {
  default = "k8sbmcs.oraclevcn.com"
}

variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}

variable "region" {
  default = "us-phoenix-1"
}

variable "vcn_dns_name" {
  default = "k8sbmcs"
}

variable "disable_auto_retries" {
  default = "false"
}

variable "private_key_password" {
  default = ""
}

variable "label_prefix" {
  description = "To create unique identifier for multiple clusters in a compartment."
  type        = "string"
  default     = ""
}

variable "additional_etcd_security_lists_ids" {
  type    = "list"
  default = []
}

variable "additional_k8s_master_security_lists_ids" {
  type    = "list"
  default = []
}

variable "additional_k8s_worker_security_lists_ids" {
  type    = "list"
  default = []
}

# Instance shape, e.g. VM.Standard1.1, VM.Standard1.2, VM.Standard1.4, ..., BM.Standard1.36, ...
variable "etcdShape" {
  default = "VM.Standard1.1"
}

variable "k8sMasterShape" {
  default = "VM.Standard1.1"
}

variable "k8sWorkerShape" {
  default = "VM.Standard1.2"
}

variable "k8sWorkerAd1Count" {
  default = 1
}

variable "k8sWorkerAd2Count" {
  default = 0
}

variable "k8sWorkerAd3Count" {
  default = 0
}

variable "k8sMasterAd1Count" {
  default = 1
}

variable "k8sMasterAd2Count" {
  default = 0
}

variable "k8sMasterAd3Count" {
  default = 0
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

variable "ssh_public_key_openssh" {
  description = "SSH public key in OpenSSH authorized_keys format for instances (generated if left blank)"
  type        = "string"
  default     = ""
}

variable "flannel_network_cidr" {
  description = "A CIDR notation IP range to use for the entire flannel network"
  type        = "string"
  default     = "10.99.0.0/16"
}

variable "etcd_cluster_ingress" {
  description = "A CIDR notation IP range that is allowed to access the etcd cluster"
  default     = "10.0.0.0/16"
}

variable "etcd_ssh_ingress" {
  description = "A CIDR notation IP range that is allowed to SSH to etcd nodes"
  default     = "10.0.0.0/16"
}

variable "master_ssh_ingress" {
  description = "A CIDR notation IP range that is allowed to SSH to master nodes"
  default     = "10.0.0.0/16"
}

variable "master_https_ingress" {
  description = "A CIDR notation IP range that is allowed to access the HTTPs port on the master nodes"
  default     = "10.0.0.0/16"
}

variable "worker_ssh_ingress" {
  description = "A CIDR notation IP range that is allowed to SSH to worker nodes"
  default     = "10.0.0.0/16"
}

variable "worker_nodeport_ingress" {
  description = "A CIDR notation IP range that is allowed to access the K8s service / NodePorts on the worker nodes"
  default     = "10.0.0.0/16"
}

variable "ssh_private_key" {
  description = "SSH private key used for instances (generated if left blank)"
  type        = "string"
  default     = ""
}

# Load Balancers
variable "etcdLBShape" {
  default = "100Mbps"
}

variable "k8sMasterLBShape" {
  default = "100Mbps"
}

# Kubernetes
variable "ca_cert" {
  description = "CA certificate (generated if left blank)"
  type        = "string"
  default     = ""
}

variable "ca_key" {
  description = "CA private key (generated if left blank)"
  type        = "string"
  default     = ""
}

variable "api_server_private_key" {
  description = "API Server private key (generated if left blank)"
  type        = "string"
  default     = ""
}

variable "api_server_cert" {
  description = "API Server certificate (generated if left blank)"
  type        = "string"
  default     = ""
}

variable "api_server_admin_token" {
  description = "admin user's bearer token for API server (generated if left blank)"
  type        = "string"
  default     = ""
}

variable "docker_ver" {
  default = "17.03.1.ce"
}

variable "etcd_ver" {
  default = "v3.2.2"
}

variable "flannel_ver" {
  default = "v0.7.1"
}

variable "k8s_ver" {
  default = "1.7.4"
}

variable "k8s_dashboard_ver" {
  default = "1.6.3"
}

variable "k8s_dns_ver" {
  default = "1.14.2"
}

variable "instance_os_ver" {
  default = "7.4"
}