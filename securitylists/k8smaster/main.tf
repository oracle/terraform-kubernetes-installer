resource "baremetal_core_security_list" "K8SMasterSubnet" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}k8sMaster_security_list"
  vcn_id         = "${var.vcn_id}"

  egress_security_rules = [
    {
      destination = "0.0.0.0/0"
      protocol    = "all"
    },
  ]

  ingress_security_rules = [
    {
      # LBaaS and internal VCN traffic
      protocol = "6"
      source   = "${lookup(var.bmc_ingress_cidrs, "LBAAS-PHOENIX-1-CIDR")}"
    },
    {
      protocol = "6"
      source   = "${lookup(var.bmc_ingress_cidrs, "LBAAS-ASHBURN-1-CIDR")}"
    },
    {
      protocol = "all"
      source   = "${lookup(var.bmc_ingress_cidrs, "VCN-CIDR")}"
    },
    {
      tcp_options {
        "max" = 22
        "min" = 22
      }

      protocol = "6"
      source   = "${var.default_ssh_ingress_cidr}"
    },
    {
      tcp_options {
        "max" = 8080
        "min" = 8080
      }

      protocol = "6"
      source   = "${lookup(var.bmc_ingress_cidrs, "VCN-CIDR")}"
    },
    {
      tcp_options {
        "max" = 443
        "min" = 443
      }

      protocol = "6"
      source   = "${var.default_https_ingress_cidr}"
    },
  ]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}
