variable "oci_flexvolume_driver_manager_version" {
  default = "0.1.0"
}

variable "tenancy" {}
variable "vcn" {}

# Flexvolume driver credentials to use.
variable "flexvolume_driver_user_ocid" {}
variable "flexvolume_driver_user_fingerprint" {}
variable "flexvolume_driver_user_private_key_path" {}
