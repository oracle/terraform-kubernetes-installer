

module "etcd-lb" {
  source           = "./loadbalancer"
  etcd_lb_enabled  = "${var.etcd_lb_enabled}"
  compartment_ocid = "${var.compartment_ocid}"
  is_private       = "${var.etcd_lb_access == "private" ? "true": "false"}"

  # Handle case where var.etcd_lb_access=public, but var.control_plane_subnet_access=private
  # etcd_subnet_0_id = "${var.subnet_ad1_id}"
  # etcd_subnet_1_id = "${var.subnet_ad2_id}"
  # FIXME add LB subnet??
  # For public access???
  # Crazy talk...
  etcd_subnet_0_id     = "${var.subnet_ad1_id}"
  etcd_subnet_1_id     = "" # ${var.subnet_ad2_id}"
  etcd_ad1_private_ips = "${module.instances-etcd-ad1.private_ips}"
  etcd_ad2_private_ips = "${module.instances-etcd-ad2.private_ips}"
  etcd_ad3_private_ips = "${module.instances-etcd-ad3.private_ips}"
  etcdAd1Count         = "${var.etcdAd1Count}"
  etcdAd2Count         = "${var.etcdAd2Count}"
  etcdAd3Count         = "${var.etcdAd3Count}"
  label_prefix         = "${var.label_prefix}"
  shape                = "${var.etcdLBShape}"
}


module "instances-etcd-ad1" {
  source                      = "./instance"
  count                       = "${var.etcdAd1Count}"
  
  availability_domain         = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  # Provider
  compartment_ocid            = "${var.compartment_ocid}"
  tenancy_ocid                = "${var.compartment_ocid}"

  # Instancey??
  display_name_prefix         = "etcd-ad1"
  hostname_label_prefix       = "etcd-ad1"
  label_prefix                = "${var.label_prefix}"
  etcd_discovery_url          = "${template_file.etcd_discovery_url.id}"
  oracle_linux_image_name     = "${var.etcd_ol_image_name}"
  shape                       = "${var.etcdShape}"
  ssh_public_key_openssh      = "${var.ssh_public_key_openssh}"

  # Network 
  subnet_id                   = "${var.subnet_ad1_id}"
  subnet_cidr                 = "10.0.20.0/24"
  domain_name                 = "${var.domain_name}"
  assign_private_ip           = "${var.etcd_maintain_private_ip == "true" ? "true": "false"}"
  control_plane_subnet_access = "${var.control_plane_subnet_access}"
  
  # Network Overlay
  flannel_backend             = "${var.flannel_config["backend"]}"
  flannel_network_cidr        = "${var.flannel_config["network_cidr"]}"
  flannel_network_subnetlen   = "${var.flannel_config["network_subnetlen"]}"
  
  # Docker
  etcd_docker_max_log_size    = "${var.docker_config["max_log_size"]}"
  etcd_docker_max_log_files   = "${var.docker_config["max_log_files"]}"

  # volume
  etcd_iscsi_volume_create    = "${var.iscsi_volume_config["create"]}"
  etcd_iscsi_volume_size      = "${var.iscsi_volume_config["size"]}"
}


module "instances-etcd-ad2" {
  source                      = "./instance"
  count                       = "${var.etcdAd2Count}"
  
  availability_domain         = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  # Provider
  compartment_ocid            = "${var.compartment_ocid}"
  tenancy_ocid                = "${var.compartment_ocid}"

  # Instancey??
  display_name_prefix         = "etcd-ad2"
  hostname_label_prefix       = "etcd-ad2"
  label_prefix                = "${var.label_prefix}"
  etcd_discovery_url          = "${template_file.etcd_discovery_url.id}"
  oracle_linux_image_name     = "${var.etcd_ol_image_name}"
  shape                       = "${var.etcdShape}"
  ssh_public_key_openssh      = "${var.ssh_public_key_openssh}"

  # Network 
  subnet_id                   = "${var.subnet_ad2_id}"
  #FIXME
  subnet_cidr                 = "10.0.21.0/24"
  domain_name                 = "${var.domain_name}"
  assign_private_ip           = "${var.etcd_maintain_private_ip == "true" ? "true": "false"}"
  control_plane_subnet_access = "${var.control_plane_subnet_access}"
  
  # Network Overlay
  flannel_backend             = "${var.flannel_config["backend"]}"
  flannel_network_cidr        = "${var.flannel_config["network_cidr"]}"
  flannel_network_subnetlen   = "${var.flannel_config["network_subnetlen"]}"
  
  # Docker
  etcd_docker_max_log_size    = "${var.docker_config["max_log_size"]}"
  etcd_docker_max_log_files   = "${var.docker_config["max_log_files"]}"

  # volume
  etcd_iscsi_volume_create    = "${var.iscsi_volume_config["create"]}"
  etcd_iscsi_volume_size      = "${var.iscsi_volume_config["size"]}"
}


module "instances-etcd-ad3" {
  source                      = "./instance"
  count                       = "${var.etcdAd3Count}"
  
  availability_domain         = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  # Provider
  compartment_ocid            = "${var.compartment_ocid}"
  tenancy_ocid                = "${var.compartment_ocid}"

  # Instancey??
  display_name_prefix         = "etcd-ad3"
  hostname_label_prefix       = "etcd-ad3"
  label_prefix                = "${var.label_prefix}"
  etcd_discovery_url          = "${template_file.etcd_discovery_url.id}"
  oracle_linux_image_name     = "${var.etcd_ol_image_name}"
  shape                       = "${var.etcdShape}"
  ssh_public_key_openssh      = "${var.ssh_public_key_openssh}"

  # Network 
  subnet_id                   = "${var.subnet_ad3_id}"
  #FIXME
  subnet_cidr                 = "10.0.22.0/24"
  domain_name                 = "${var.domain_name}"
  assign_private_ip           = "${var.etcd_maintain_private_ip == "true" ? "true": "false"}"
  control_plane_subnet_access = "${var.control_plane_subnet_access}"
  
  # Network Overlay
  flannel_backend             = "${var.flannel_config["backend"]}"
  flannel_network_cidr        = "${var.flannel_config["network_cidr"]}"
  flannel_network_subnetlen   = "${var.flannel_config["network_subnetlen"]}"
  
  # Docker
  etcd_docker_max_log_size    = "${var.docker_config["max_log_size"]}"
  etcd_docker_max_log_files   = "${var.docker_config["max_log_files"]}"

  # volume
  etcd_iscsi_volume_create    = "${var.iscsi_volume_config["create"]}"
  etcd_iscsi_volume_size      = "${var.iscsi_volume_config["size"]}"
}

