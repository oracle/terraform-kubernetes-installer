resource "baremetal_core_security_list" "monitoring" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}monitoring_security_list"
  vcn_id         = "${var.vcn_id}"

  egress_security_rules = [
    {
      destination = "0.0.0.0/0"
      protocol    = "all"
    },
  ]

  ingress_security_rules = [
    {
      # ingresss rule changes can be applied without a destroy
      protocol = "all"
      source   = "${lookup(var.internal_ingress, "orcl-VCN-CIDR")}"
    },
    {
      protocol = "1"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "min" = 22
        "max" = 22
      }
      protocol = "6"
      source   = "0.0.0.0/0"
    },
    {
      tcp_options {
        "min" = 30000
        "max" = 32767
      }
      protocol = "6"
      source   = "0.0.0.0/0"
    },
  ]
}
