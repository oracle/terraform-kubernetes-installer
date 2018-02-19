# Gets the OCID of the OS image to use
data "baremetal_core_images" "OracleLinuxImageOCID" {
  compartment_id           = "${var.compartment_ocid}"
  # Use explicit display name as default to work around Terraform/OCI issue
  # See https://github.com/oracle/terraform-provider-oci/issues/345
  display_name = "Oracle-Linux-7.4-2018.01.10-0"
}

# Cloud call to get a list of Availability Domains
data "baremetal_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}
