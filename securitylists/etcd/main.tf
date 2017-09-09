resource "baremetal_core_security_list" "EtcdSubnet" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}etcd_security_list"
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
      protocol = "6"
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
        "max" = 2380
        "min" = 2379
      }

      protocol = "6"
      source   = "${var.default_etcd_cluster_ingress_cidr}"
    },
  ]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}
