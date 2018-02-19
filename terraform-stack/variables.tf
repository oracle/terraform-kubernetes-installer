variable "disable_auto_retries" {
  default = "true"
}

# BMCS Service
variable "tenancy_ocid" {}

variable "compartment_ocid" {}

variable "domain_name" {
  default = "coreservices.odxprime.oraclevcn.com"
}

variable "vcn_dns_name" {
  default = "coreservices"
}

variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}

variable "region" {
  default = "us-phoenix-1"
}

variable "os_image_ocid" {
  default = ""
}

variable "monitoringShape" {
  default = "VM.DenseIO1.4"
}

variable "loggingShape" {
  default = "VM.DenseIO1.4"
}

variable "loggingBlockVolumeSize" {
  default = "262144"
}

variable "monitoringBlockVolumeSize" {
  default = "262144"
}

variable "logging-instance-ad" {
  default = "1"
}

variable "monitoring-instance-ad" {
  default = "1"
}

variable "ssh_private_key" {
  description = "SSH private key used for instances (generated if left blank)"
  type        = "string"
  default     = ""
}

variable "ssh_public_key_openssh" {
  description = "SSH public key in OpenSSH authorized_keys format for instances (generated if left blank)"
  type        = "string"
  default     = ""
}

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

variable "label_prefix" {
  description = "To create unique identifier for multiple deployments in a single compartment."
  type        = "string"
  default     = ""
}

variable "oracle_internal_network_cidrs" {
  type = "map"

  default = {
    ADC-CIDR             = "137.254.7.160/27"
    WHQ-CIDR             = "148.87.23.0/27"
    RMDC-CIDR            = "148.87.66.160/27"
    OCNA-CIDR            = "160.34.0.0/16"
    Seattle-CIDR         = "209.17.37.96/27"
    ASH-CIDR             = "209.17.40.32/27"
    UK-CIDR              = "141.143.0.0/16"
    India-CIDR           = "196.15.23.0/27"
    Brazil-CIDR          = "198.49.164.160/27"
    Singapore-CIDR       = "198.17.70.0/27"
    NEW-Singapore-CIDR   = "192.188.170.80/28"
    Japan-CIDR           = "202.45.129.176/28"
    Sydney-CIDR          = "202.92.67.176/29"
    WWW-PROXY-CIDR       = "148.87.19.0/24"
    LBAAS-PHOENIX-1-CIDR = "129.144.0.0/12"
    LBAAS-ASHBURN-1-CIDR = "129.213.0.0/16"
    BMC-CIDR             = "129.144.0.0/12"
    VPN-CIDR             = "156.151.0.0/16"
    VCN-CIDR             = "10.0.0.0/16"
  }
}
