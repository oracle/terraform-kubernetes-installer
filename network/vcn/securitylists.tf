resource "oci_core_security_list" "EtcdSubnet" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}etcd_security_list"
  vcn_id         = "${oci_core_virtual_network.CompleteVCN.id}"

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
      source   = "${var.etcd_ssh_ingress}"
    },
    {
      tcp_options {
        "max" = 2380
        "min" = 2379
      }

      protocol = "6"
      source   = "${var.etcd_cluster_ingress}"
    },
  ]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_security_list" "K8SMasterSubnet" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}k8sMaster_security_list"
  vcn_id         = "${oci_core_virtual_network.CompleteVCN.id}"

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
      source   = "${var.master_ssh_ingress}"
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
      source   = "${var.master_https_ingress}"
    },
  ]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_security_list" "K8SWorkerSubnet" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "${var.label_prefix}k8sWorker_security_list"
  vcn_id         = "${oci_core_virtual_network.CompleteVCN.id}"

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
      source   = "${var.worker_ssh_ingress}"
    },
    {
      tcp_options {
        "min" = 30000
        "max" = 32767
      }

      protocol = "6"
      source   = "${var.worker_nodeport_ingress}"
    },
  ]

  provisioner "local-exec" {
    command = "sleep 5"
  }
}
