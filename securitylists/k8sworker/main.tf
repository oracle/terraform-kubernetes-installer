resource "oci_core_security_list" "K8SWorkerSubnet" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}k8sWorker_security_list"
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
      # External traffic
      tcp_options {
        "max" = 22
        "min" = 22
      }

      protocol = "6"
      source   = "${var.default_ssh_ingress_cidr}"
    },
    {
      tcp_options {
        "min" = 30000
        "max" = 32767
      }

      protocol = "6"
      source   = "${var.default_node_port_ingress_cidr}"
    },
  ]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}
