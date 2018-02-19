### VCN

module "vcn" {
  source           = "./modules/vcn"
  compartment_ocid = "${var.compartment_ocid}"
  vcn_dns_name     = "${var.vcn_dns_name}"
  label_prefix     = "${var.label_prefix}"
}

### Security lists

module "security-list-monitoring" {
  source           = "./modules/securitylists/monitoring"
  compartment_ocid = "${var.compartment_ocid}"
  vcn_id           = "${module.vcn.id}"
  label_prefix     = "${var.label_prefix}"
}

module "security-list-logging" {
  source           = "./modules/securitylists/logging"
  compartment_ocid = "${var.compartment_ocid}"
  vcn_id           = "${module.vcn.id}"
  label_prefix     = "${var.label_prefix}"
}

### Subnets

module "subnet-logging-1" {
  source              = "./modules/subnets"
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ADs.availability_domains[var.logging-instance-ad - 1],"name")}"
  cidr_block          = "10.0.30.0/24"
  compartment_ocid    = "${var.compartment_ocid}"
  dhcp_options_id     = "${module.vcn.dhcp_options_id}"
  route_table_id      = "${module.vcn.route_for_complete_id}"
  security_list_id    = ["${module.security-list-logging.id}"]
  vcn_id              = "${module.vcn.id}"
  display_name        = "logging-ad${var.logging-instance-ad}"
  dns_label           = "loggingad${var.logging-instance-ad}"
}

module "subnet-logging-2" {
  source = "./modules/subnets"

  # TODO unsure about the AD var logic. Basically, we want this subnet to be in a different AD than the other subnet.
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ADs.availability_domains[var.logging-instance-ad == "3" ? var.logging-instance-ad - 1 : var.logging-instance-ad],"name")}"
  cidr_block          = "10.0.31.0/24"
  compartment_ocid    = "${var.compartment_ocid}"
  dhcp_options_id     = "${module.vcn.dhcp_options_id}"
  route_table_id      = "${module.vcn.route_for_complete_id}"
  security_list_id    = ["${module.security-list-logging.id}"]
  vcn_id              = "${module.vcn.id}"
  display_name        = "logging-ad${var.logging-instance-ad}-2"
  dns_label           = "loggingad${var.logging-instance-ad}2"
}

module "subnet-monitoring-1" {
  source              = "./modules/subnets"
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ADs.availability_domains[var.monitoring-instance-ad - 1],"name")}"
  cidr_block          = "10.0.20.0/24"
  compartment_ocid    = "${var.compartment_ocid}"
  dhcp_options_id     = "${module.vcn.dhcp_options_id}"
  route_table_id      = "${module.vcn.route_for_complete_id}"
  security_list_id    = ["${module.security-list-monitoring.id}"]
  vcn_id              = "${module.vcn.id}"
  display_name        = "monitoring-ad${var.monitoring-instance-ad}"
  dns_label           = "monitoringad${var.monitoring-instance-ad}"
}

module "subnet-monitoring-2" {
  source = "./modules/subnets"

  # TODO unsure about the AD var logic. Basically, we want this subnet to be in a different AD than the other subnet.
  availability_domain = "${lookup(data.baremetal_identity_availability_domains.ADs.availability_domains[var.monitoring-instance-ad == "3" ? var.monitoring-instance-ad - 1 : var.monitoring-instance-ad],"name")}"
  cidr_block          = "10.0.22.0/24"
  compartment_ocid    = "${var.compartment_ocid}"
  dhcp_options_id     = "${module.vcn.dhcp_options_id}"
  route_table_id      = "${module.vcn.route_for_complete_id}"
  security_list_id    = ["${module.security-list-monitoring.id}"]
  vcn_id              = "${module.vcn.id}"
  display_name        = "monitoring-ad${var.monitoring-instance-ad}-2"
  dns_label           = "monitoringad${var.monitoring-instance-ad}2"
}
