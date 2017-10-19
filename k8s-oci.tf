### CA and Cluster Certificates

module "k8s-tls" {
  source                 = "tls/"
  api_server_private_key = "${var.api_server_private_key}"
  api_server_cert        = "${var.api_server_cert}"
  ca_cert                = "${var.ca_cert}"
  ca_key                 = "${var.ca_key}"
  api_server_admin_token = "${var.api_server_admin_token}"
  master_lb_public_ip    = "${module.k8smaster-public-lb.ip_addresses[0]}"
  ssh_private_key        = "${var.ssh_private_key}"
  ssh_public_key_openssh = "${var.ssh_public_key_openssh}"
}

### VCN

module "vcn" {
  source           = "vcn"
  compartment_ocid = "${var.compartment_ocid}"
  label_prefix     = "${var.label_prefix}"
  vcn_dns_name     = "${var.vcn_dns_name}"
}

### Subnets

module "security-list-etcd" {
  source                            = "securitylists/etcd"
  compartment_ocid                  = "${var.compartment_ocid}"
  default_etcd_cluster_ingress_cidr = "${var.etcd_cluster_ingress}"
  default_ssh_ingress_cidr          = "${var.etcd_ssh_ingress}"
  label_prefix                      = "${var.label_prefix}"
  vcn_id                            = "${module.vcn.id}"
}

module "subnet-etcd-ad1" {
  source                        = "subnets/etcd"
  additional_security_lists_ids = ["${var.additional_etcd_security_lists_ids}"]
  availability_domain           = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block                    = "10.0.20.0/24"
  compartment_ocid              = "${var.compartment_ocid}"
  dhcp_options_id               = "${module.vcn.dhcp_options_id}"
  display_name                  = "etcdSubnetAd1"
  dns_label                     = "etcdsubnet1"
  label_prefix                  = "${var.label_prefix}"
  route_table_id                = "${module.vcn.route_for_complete_id}"
  security_list_id              = ["${module.security-list-etcd.id}"]
  vcn_id                        = "${module.vcn.id}"
}

module "subnet-etcd-ad2" {
  source                        = "subnets/etcd"
  additional_security_lists_ids = ["${var.additional_etcd_security_lists_ids}"]
  availability_domain           = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block                    = "10.0.21.0/24"
  compartment_ocid              = "${var.compartment_ocid}"
  dhcp_options_id               = "${module.vcn.dhcp_options_id}"
  display_name                  = "etcdSubnetAd2"
  dns_label                     = "etcdsubnet2"
  label_prefix                  = "${var.label_prefix}"
  route_table_id                = "${module.vcn.route_for_complete_id}"
  security_list_id              = ["${module.security-list-etcd.id}"]
  vcn_id                        = "${module.vcn.id}"
}

module "subnet-etcd-ad3" {
  source                        = "subnets/etcd"
  additional_security_lists_ids = ["${var.additional_etcd_security_lists_ids}"]
  availability_domain           = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  cidr_block                    = "10.0.22.0/24"
  compartment_ocid              = "${var.compartment_ocid}"
  dhcp_options_id               = "${module.vcn.dhcp_options_id}"
  display_name                  = "etcdSubnetAd3"
  dns_label                     = "etcdsubnet3"
  label_prefix                  = "${var.label_prefix}"
  route_table_id                = "${module.vcn.route_for_complete_id}"
  security_list_id              = ["${module.security-list-etcd.id}"]
  vcn_id                        = "${module.vcn.id}"
}

module "security-list-k8smaster" {
  source                     = "securitylists/k8smaster"
  compartment_ocid           = "${var.compartment_ocid}"
  default_ssh_ingress_cidr   = "${var.master_ssh_ingress}"
  default_https_ingress_cidr = "${var.master_https_ingress}"
  label_prefix               = "${var.label_prefix}"
  vcn_id                     = "${module.vcn.id}"
}

module "subnet-k8sMasterSubnetAd1" {
  source                        = "subnets/k8smaster"
  additional_security_lists_ids = ["${var.additional_k8s_master_security_lists_ids}"]
  availability_domain           = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block                    = "10.0.30.0/24"
  compartment_ocid              = "${var.compartment_ocid}"
  dhcp_options_id               = "${module.vcn.dhcp_options_id}"
  display_name                  = "k8sMasterSubnetAd1"
  dns_label                     = "k8smasterad1"
  label_prefix                  = "${var.label_prefix}"
  route_table_id                = "${module.vcn.route_for_complete_id}"
  security_list_id              = ["${module.security-list-k8smaster.id}"]
  vcn_id                        = "${module.vcn.id}"
}

module "subnet-k8sMasterSubnetAd2" {
  source                        = "subnets/k8smaster"
  additional_security_lists_ids = ["${var.additional_k8s_master_security_lists_ids}"]
  availability_domain           = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block                    = "10.0.31.0/24"
  compartment_ocid              = "${var.compartment_ocid}"
  dhcp_options_id               = "${module.vcn.dhcp_options_id}"
  display_name                  = "k8sMasterSubnetAd2"
  dns_label                     = "k8smasterad2"
  label_prefix                  = "${var.label_prefix}"
  route_table_id                = "${module.vcn.route_for_complete_id}"
  security_list_id              = ["${module.security-list-k8smaster.id}"]
  vcn_id                        = "${module.vcn.id}"
}

module "subnet-k8sMasterSubnetAd3" {
  source                        = "subnets/k8smaster"
  additional_security_lists_ids = ["${var.additional_k8s_master_security_lists_ids}"]
  availability_domain           = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  cidr_block                    = "10.0.32.0/24"
  compartment_ocid              = "${var.compartment_ocid}"
  dhcp_options_id               = "${module.vcn.dhcp_options_id}"
  display_name                  = "k8sMasterSubnetAd3"
  dns_label                     = "k8smasterad3"
  label_prefix                  = "${var.label_prefix}"
  route_table_id                = "${module.vcn.route_for_complete_id}"
  security_list_id              = ["${module.security-list-k8smaster.id}"]
  vcn_id                        = "${module.vcn.id}"
}

module "security-list-k8sworker" {
  source                         = "securitylists/k8sworker"
  compartment_ocid               = "${var.compartment_ocid}"
  default_ssh_ingress_cidr       = "${var.worker_ssh_ingress}"
  default_node_port_ingress_cidr = "${var.worker_nodeport_ingress}"
  vcn_id                         = "${module.vcn.id}"
  label_prefix                   = "${var.label_prefix}"
}

module "subnet-k8sWorkerSubnetAd1" {
  source                        = "subnets/k8sworker"
  additional_security_lists_ids = ["${var.additional_k8s_worker_security_lists_ids}"]
  availability_domain           = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block                    = "10.0.40.0/24"
  compartment_ocid              = "${var.compartment_ocid}"
  dhcp_options_id               = "${module.vcn.dhcp_options_id}"
  display_name                  = "k8sWorkerSubnetAd1"
  dns_label                     = "k8sworkerad1"
  label_prefix                  = "${var.label_prefix}"
  route_table_id                = "${module.vcn.route_for_complete_id}"
  security_list_id              = ["${module.security-list-k8sworker.id}"]
  vcn_id                        = "${module.vcn.id}"
}

module "subnet-k8sWorkerSubnetAd2" {
  source                        = "subnets/k8sworker"
  additional_security_lists_ids = ["${var.additional_k8s_worker_security_lists_ids}"]
  availability_domain           = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block                    = "10.0.41.0/24"
  compartment_ocid              = "${var.compartment_ocid}"
  dhcp_options_id               = "${module.vcn.dhcp_options_id}"
  display_name                  = "k8sWorkerSubnetAd2"
  dns_label                     = "k8sworkerad2"
  label_prefix                  = "${var.label_prefix}"
  route_table_id                = "${module.vcn.route_for_complete_id}"
  security_list_id              = ["${module.security-list-k8sworker.id}"]
  vcn_id                        = "${module.vcn.id}"
}

module "subnet-k8sWorkerSubnetAd3" {
  source                        = "subnets/k8sworker"
  additional_security_lists_ids = ["${var.additional_k8s_worker_security_lists_ids}"]
  availability_domain           = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  cidr_block                    = "10.0.42.0/24"
  compartment_ocid              = "${var.compartment_ocid}"
  dhcp_options_id               = "${module.vcn.dhcp_options_id}"
  display_name                  = "k8sWorkerSubnetAd3"
  dns_label                     = "k8sworkerad3"
  label_prefix                  = "${var.label_prefix}"
  route_table_id                = "${module.vcn.route_for_complete_id}"
  security_list_id              = ["${module.security-list-k8sworker.id}"]
  vcn_id                        = "${module.vcn.id}"
}

### Instances

module "instances-etcd-ad1" {
  source                    = "instances/etcd"
  count                     = "${var.etcdAd1Count}"
  availability_domain       = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_ocid          = "${var.compartment_ocid}"
  display_name              = "etcd-ad1"
  domain_name               = "${var.domain_name}"
  etcd_discovery_url        = "${template_file.etcd_discovery_url.id}"
  flannel_backend           = "VXLAN"
  flannel_network_cidr      = "10.99.0.0/16"
  flannel_network_subnetlen = 24
  hostname_label            = "etcd-ad1"
  instance_os_ver           = "${var.instance_os_ver}"
  label_prefix              = "${var.label_prefix}"
  shape                     = "${var.etcdShape}"
  ssh_public_key_openssh    = "${module.k8s-tls.ssh_public_key_openssh}"
  subnet_id                 = "${module.subnet-etcd-ad1.id}"
  tenancy_ocid              = "${var.compartment_ocid}"
}

module "instances-etcd-ad2" {
  source                    = "instances/etcd"
  count                     = "${var.etcdAd2Count}"
  availability_domain       = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  compartment_ocid          = "${var.compartment_ocid}"
  display_name              = "etcd-ad2"
  domain_name               = "${var.domain_name}"
  etcd_discovery_url        = "${template_file.etcd_discovery_url.id}"
  flannel_backend           = "VXLAN"
  flannel_network_cidr      = "10.99.0.0/16"
  flannel_network_subnetlen = 24
  hostname_label            = "etcd-ad2"
  instance_os_ver           = "${var.instance_os_ver}"
  label_prefix              = "${var.label_prefix}"
  shape                     = "${var.etcdShape}"
  ssh_public_key_openssh    = "${module.k8s-tls.ssh_public_key_openssh}"
  subnet_id                 = "${module.subnet-etcd-ad2.id}"
  tenancy_ocid              = "${var.compartment_ocid}"
}

module "instances-etcd-ad3" {
  source                    = "instances/etcd"
  count                     = "${var.etcdAd3Count}"
  availability_domain       = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  compartment_ocid          = "${var.compartment_ocid}"
  display_name              = "etcd-ad3"
  docker_ver                = "${var.docker_ver}"
  domain_name               = "${var.domain_name}"
  etcd_discovery_url        = "${template_file.etcd_discovery_url.id}"
  etcd_ver                  = "${var.etcd_ver}"
  flannel_backend           = "VXLAN"
  flannel_network_cidr      = "10.99.0.0/16"
  flannel_network_subnetlen = 24
  hostname_label            = "etcd-ad3"
  instance_os_ver           = "${var.instance_os_ver}"
  label_prefix              = "${var.label_prefix}"
  shape                     = "${var.etcdShape}"
  ssh_public_key_openssh    = "${module.k8s-tls.ssh_public_key_openssh}"
  subnet_id                 = "${module.subnet-etcd-ad3.id}"
  tenancy_ocid              = "${var.compartment_ocid}"
}

module "instances-k8smaster-ad1" {
  source                     = "instances/k8smaster"
  count                      = "${var.k8sMasterAd1Count}"
  api_server_cert_pem        = "${module.k8s-tls.api_server_cert_pem}"
  api_server_count           = "${var.k8sMasterAd1Count + var.k8sMasterAd2Count + var.k8sMasterAd3Count}"
  api_server_private_key_pem = "${module.k8s-tls.api_server_private_key_pem}"
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  k8s_apiserver_token_admin  = "${module.k8s-tls.api_server_admin_token}"
  compartment_ocid           = "${var.compartment_ocid}"
  display_name_prefix        = "k8s-master-ad1"
  docker_ver                 = "${var.docker_ver}"
  domain_name                = "${var.domain_name}"
  etcd_discovery_url         = "${template_file.etcd_discovery_url.id}"
  etcd_lb                    = "http://${module.etcd-private-lb.ip_addresses[0]}:2379"
  etcd_ver                   = "${var.etcd_ver}"
  flannel_ver                = "${var.flannel_ver}"
  hostname_label_prefix      = "k8s-master-ad1"
  instance_os_ver            = "${var.instance_os_ver}"
  k8s_dashboard_ver          = "${var.k8s_dashboard_ver}"
  k8s_dns_ver                = "${var.k8s_dns_ver}"
  k8s_ver                    = "${var.k8s_ver}"
  label_prefix               = "${var.label_prefix}"
  root_ca_pem                = "${module.k8s-tls.root_ca_pem}"
  shape                      = "${var.k8sMasterShape}"
  ssh_public_key_openssh     = "${module.k8s-tls.ssh_public_key_openssh}"
  subnet_id                  = "${module.subnet-k8sMasterSubnetAd1.id}"
  tenancy_ocid               = "${var.compartment_ocid}"
}

module "instances-k8smaster-ad2" {
  source                     = "instances/k8smaster"
  count                      = "${var.k8sMasterAd2Count}"
  api_server_cert_pem        = "${module.k8s-tls.api_server_cert_pem}"
  api_server_count           = "${var.k8sMasterAd1Count + var.k8sMasterAd2Count + var.k8sMasterAd3Count}"
  api_server_private_key_pem = "${module.k8s-tls.api_server_private_key_pem}"
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  k8s_apiserver_token_admin  = "${module.k8s-tls.api_server_admin_token}"
  compartment_ocid           = "${var.compartment_ocid}"
  display_name_prefix        = "k8s-master-ad2"
  docker_ver                 = "${var.docker_ver}"
  domain_name                = "${var.domain_name}"
  etcd_discovery_url         = "${template_file.etcd_discovery_url.id}"
  etcd_lb                    = "http://${module.etcd-private-lb.ip_addresses[0]}:2379"
  etcd_ver                   = "${var.etcd_ver}"
  flannel_ver                = "${var.flannel_ver}"
  hostname_label_prefix      = "k8s-master-ad2"
  instance_os_ver            = "${var.instance_os_ver}"
  k8s_dashboard_ver          = "${var.k8s_dashboard_ver}"
  k8s_dns_ver                = "${var.k8s_dns_ver}"
  k8s_ver                    = "${var.k8s_ver}"
  label_prefix               = "${var.label_prefix}"
  root_ca_pem                = "${module.k8s-tls.root_ca_pem}"
  shape                      = "${var.k8sMasterShape}"
  ssh_public_key_openssh     = "${module.k8s-tls.ssh_public_key_openssh}"
  subnet_id                  = "${module.subnet-k8sMasterSubnetAd2.id}"
  tenancy_ocid               = "${var.compartment_ocid}"
}

module "instances-k8smaster-ad3" {
  source                     = "instances/k8smaster"
  count                      = "${var.k8sMasterAd3Count}"
  api_server_cert_pem        = "${module.k8s-tls.api_server_cert_pem}"
  api_server_count           = "${var.k8sMasterAd1Count + var.k8sMasterAd2Count + var.k8sMasterAd3Count}"
  api_server_private_key_pem = "${module.k8s-tls.api_server_private_key_pem}"
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  k8s_apiserver_token_admin  = "${module.k8s-tls.api_server_admin_token}"
  compartment_ocid           = "${var.compartment_ocid}"
  display_name_prefix        = "k8s-master-ad3"
  docker_ver                 = "${var.docker_ver}"
  domain_name                = "${var.domain_name}"
  etcd_discovery_url         = "${template_file.etcd_discovery_url.id}"
  etcd_lb                    = "http://${module.etcd-private-lb.ip_addresses[0]}:2379"
  etcd_ver                   = "${var.etcd_ver}"
  flannel_ver                = "${var.flannel_ver}"
  hostname_label_prefix      = "k8s-master-ad3"
  instance_os_ver            = "${var.instance_os_ver}"
  k8s_dashboard_ver          = "${var.k8s_dashboard_ver}"
  k8s_dns_ver                = "${var.k8s_dns_ver}"
  k8s_ver                    = "${var.k8s_ver}"
  label_prefix               = "${var.label_prefix}"
  root_ca_pem                = "${module.k8s-tls.root_ca_pem}"
  shape                      = "${var.k8sMasterShape}"
  ssh_public_key_openssh     = "${module.k8s-tls.ssh_public_key_openssh}"
  subnet_id                  = "${module.subnet-k8sMasterSubnetAd3.id}"
  tenancy_ocid               = "${var.compartment_ocid}"
}

module "instances-k8sworker-ad1" {
  source                     = "instances/k8sworker"
  count                      = "${var.k8sWorkerAd1Count}"
  api_server_cert_pem        = "${module.k8s-tls.api_server_cert_pem}"
  api_server_private_key_pem = "${module.k8s-tls.api_server_private_key_pem}"
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  compartment_ocid           = "${var.compartment_ocid}"
  display_name_prefix        = "k8s-worker-ad1"
  docker_ver                 = "${var.docker_ver}"
  domain_name                = "${var.domain_name}"
  etcd_discovery_url         = "${template_file.etcd_discovery_url.id}"
  etcd_lb                    = "http://${module.etcd-private-lb.ip_addresses[0]}:2379"
  etcd_ver                   = "${var.etcd_ver}"
  flannel_ver                = "${var.flannel_ver}"
  hostname_label_prefix      = "k8s-worker-ad1"
  instance_os_ver            = "${var.instance_os_ver}"
  k8s_ver                    = "${var.k8s_ver}"
  label_prefix               = "${var.label_prefix}"
  master_lb                  = "https://${module.k8smaster-public-lb.ip_addresses[0]}:443"
  region                     = "${var.region}"
  root_ca_key                = "${module.k8s-tls.root_ca_key}"
  root_ca_pem                = "${module.k8s-tls.root_ca_pem}"
  shape                      = "${var.k8sWorkerShape}"
  ssh_private_key            = "${module.k8s-tls.ssh_private_key}"
  ssh_public_key_openssh     = "${module.k8s-tls.ssh_public_key_openssh}"
  subnet_id                  = "${module.subnet-k8sWorkerSubnetAd1.id}"
  tenancy_ocid               = "${var.compartment_ocid}"
}

module "instances-k8sworker-ad2" {
  source                     = "instances/k8sworker"
  count                      = "${var.k8sWorkerAd2Count}"
  api_server_cert_pem        = "${module.k8s-tls.api_server_cert_pem}"
  api_server_private_key_pem = "${module.k8s-tls.api_server_private_key_pem}"
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  compartment_ocid           = "${var.compartment_ocid}"
  display_name_prefix        = "k8s-worker-ad2"
  docker_ver                 = "${var.docker_ver}"
  domain_name                = "${var.domain_name}"
  etcd_discovery_url         = "${template_file.etcd_discovery_url.id}"
  etcd_lb                    = "http://${module.etcd-private-lb.ip_addresses[0]}:2379"
  etcd_ver                   = "${var.etcd_ver}"
  flannel_ver                = "${var.flannel_ver}"
  hostname_label_prefix      = "k8s-worker-ad2"
  instance_os_ver            = "${var.instance_os_ver}"
  k8s_ver                    = "${var.k8s_ver}"
  label_prefix               = "${var.label_prefix}"
  master_lb                  = "https://${module.k8smaster-public-lb.ip_addresses[0]}:443"
  region                     = "${var.region}"
  root_ca_key                = "${module.k8s-tls.root_ca_key}"
  root_ca_pem                = "${module.k8s-tls.root_ca_pem}"
  shape                      = "${var.k8sWorkerShape}"
  ssh_private_key            = "${module.k8s-tls.ssh_private_key}"
  ssh_public_key_openssh     = "${module.k8s-tls.ssh_public_key_openssh}"
  subnet_id                  = "${module.subnet-k8sWorkerSubnetAd2.id}"
  tenancy_ocid               = "${var.compartment_ocid}"
}

module "instances-k8sworker-ad3" {
  source                     = "instances/k8sworker"
  count                      = "${var.k8sWorkerAd3Count}"
  api_server_cert_pem        = "${module.k8s-tls.api_server_cert_pem}"
  api_server_private_key_pem = "${module.k8s-tls.api_server_private_key_pem}"
  availability_domain        = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  compartment_ocid           = "${var.compartment_ocid}"
  display_name_prefix        = "k8s-worker-ad3"
  docker_ver                 = "${var.docker_ver}"
  domain_name                = "${var.domain_name}"
  etcd_discovery_url         = "${template_file.etcd_discovery_url.id}"
  etcd_lb                    = "http://${module.etcd-private-lb.ip_addresses[0]}:2379"
  etcd_ver                   = "${var.etcd_ver}"
  flannel_ver                = "${var.flannel_ver}"
  hostname_label_prefix      = "k8s-worker-ad3"
  instance_os_ver           = "${var.instance_os_ver}"
  k8s_ver                    = "${var.k8s_ver}"
  label_prefix               = "${var.label_prefix}"
  master_lb                  = "https://${module.k8smaster-public-lb.ip_addresses[0]}:443"
  region                     = "${var.region}"
  root_ca_key                = "${module.k8s-tls.root_ca_key}"
  root_ca_pem                = "${module.k8s-tls.root_ca_pem}"
  shape                      = "${var.k8sWorkerShape}"
  ssh_private_key            = "${module.k8s-tls.ssh_private_key}"
  ssh_public_key_openssh     = "${module.k8s-tls.ssh_public_key_openssh}"
  subnet_id                  = "${module.subnet-k8sWorkerSubnetAd3.id}"
  tenancy_ocid               = "${var.compartment_ocid}"
}

### Load Balancers

module "etcd-private-lb" {
  source               = "loadbalancers/etcd"
  compartment_ocid     = "${var.compartment_ocid}"
  etcd_subnet_0_id     = "${module.subnet-etcd-ad1.id}"
  etcd_ad1_private_ips = "${module.instances-etcd-ad1.private_ips}"
  etcd_ad2_private_ips = "${module.instances-etcd-ad2.private_ips}"
  etcd_ad3_private_ips = "${module.instances-etcd-ad3.private_ips}"
  etcdAd1Count         = "${var.etcdAd1Count}"
  etcdAd2Count         = "${var.etcdAd2Count}"
  etcdAd3Count         = "${var.etcdAd3Count}"
  label_prefix         = "${var.label_prefix}"
  shape                = "${var.etcdLBShape}"
}

module "k8smaster-public-lb" {
  source                    = "loadbalancers/k8smaster"
  compartment_ocid          = "${var.compartment_ocid}"
  k8smaster_subnet_0_id     = "${module.subnet-k8sMasterSubnetAd1.id}"
  k8smaster_subnet_1_id     = "${module.subnet-k8sMasterSubnetAd2.id}"
  k8smaster_ad1_private_ips = "${module.instances-k8smaster-ad1.private_ips}"
  k8smaster_ad2_private_ips = "${module.instances-k8smaster-ad2.private_ips}"
  k8smaster_ad3_private_ips = "${module.instances-k8smaster-ad3.private_ips}"
  k8sMasterAd1Count         = "${var.k8sMasterAd1Count}"
  k8sMasterAd2Count         = "${var.k8sMasterAd2Count}"
  k8sMasterAd3Count         = "${var.k8sMasterAd3Count}"
  label_prefix              = "${var.label_prefix}"
  shape                     = "${var.k8sMasterLBShape}"
}

module "kubeconfig" {
  source                     = "kubernetes/kubeconfig"
  api_server_private_key_pem = "${module.k8s-tls.api_server_private_key_pem}"
  api_server_cert_pem        = "${module.k8s-tls.api_server_cert_pem}"
  k8s_master                 = "https://${module.k8smaster-public-lb.ip_addresses[0]}:443"
}
