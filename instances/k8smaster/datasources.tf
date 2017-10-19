# Gets the OCID of the OS image to use
data "oci_core_images" "ImageOCID" {
  compartment_id           = "${var.compartment_ocid}"
  operating_system         = "Oracle Linux"
  operating_system_version = "${var.instance_os_ver}"
}

# Cloud call to get a list of Availability Domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

data "template_file" "setup-template" {
  template = "${file("${path.module}/scripts/setup.template.sh")}"

  vars = {
    domain_name        = "${var.domain_name}"
    docker_ver         = "${var.docker_ver}"
    etcd_ver           = "${var.etcd_ver}"
    flannel_ver        = "${var.flannel_ver}"
    k8s_ver            = "${var.k8s_ver}"
    etcd_lb            = "${var.etcd_lb}"
    etcd_discovery_url = "${file("${path.root}/generated/discovery${var.etcd_discovery_url}")}"
  }
}

data "template_file" "setup-preflight" {
  template = "${file("${path.module}/scripts/setup.preflight.sh")}"

  vars = {
    k8s_ver = "${var.k8s_ver}"
  }
}

data "template_file" "kube-apiserver" {
  template = "${file("${path.module}/manifests/kube-apiserver.yaml")}"

  vars = {
    api_server_count = "${var.api_server_count}"
    etcd_lb          = "${var.etcd_lb}"
    domain_name      = "${var.domain_name}"
    k8s_ver          = "${var.k8s_ver}"
  }
}

data "template_file" "kubelet-service" {
  template = "${file("${path.module}/scripts/kubelet.service")}"

  vars = {
    k8s_ver = "${var.k8s_ver}"
  }
}

data "template_file" "kube-controller-manager" {
  template = "${file("${path.module}/manifests/kube-controller-manager.yaml")}"

  vars = {
    k8s_ver = "${var.k8s_ver}"
  }
}

data "template_file" "kube-dns" {
  template = "${file("${path.module}/manifests/kube-dns.yaml")}"

  vars = {
    pillar_dns_domain = "cluster.local"
    k8s_dns_ver       = "${var.k8s_dns_ver}"
  }
}

data "template_file" "kube-proxy" {
  template = "${file("${path.module}/manifests/kube-proxy.yaml")}"

  vars = {
    k8s_ver = "${var.k8s_ver}"
  }
}

data "template_file" "kube-scheduler" {
  template = "${file("${path.module}/manifests/kube-scheduler.yaml")}"

  vars = {
    k8s_ver = "${var.k8s_ver}"
  }
}

data "template_file" "kube-dashboard" {
  template = "${file("${path.module}/manifests/kubernetes-dashboard.yaml")}"

  vars = {
    k8s_dashboard_ver = "${var.k8s_dashboard_ver}"
  }
}

data "template_file" "kube-rbac" {
  template = "${file("${path.module}/manifests/kube-rbac-role-binding.yaml")}"
}

data "template_file" "docker-service" {
  template = "${file("${path.module}/scripts/docker.service")}"
}

data "template_file" "flannel-service" {
  template = "${file("${path.module}/scripts/flannel.service")}"
}

data "template_file" "cnibridge-service" {
  template = "${file("${path.module}/scripts/cni-bridge.service")}"
}

data "template_file" "cnibridge-sh" {
  template = "${file("${path.module}/scripts/cni-bridge.sh")}"
}

data "template_file" "token_auth_file" {
  template = "${file("${path.module}/scripts/token_auth.csv")}"

  vars {
    token_admin = "${var.k8s_apiserver_token_admin}"
  }
}

data "template_file" "kube_master_cloud_init_file" {
  template = "${file("${path.module}/cloud_init/bootstrap.template.yaml")}"

  vars = {
    k8s_ver                                  = "${var.k8s_ver}"
    setup_preflight_sh_content               = "${base64encode(data.template_file.setup-preflight.rendered)}"
    setup_template_sh_content                = "${base64encode(data.template_file.setup-template.rendered)}"
    kube_apiserver_template_content          = "${base64encode(data.template_file.kube-apiserver.rendered)}"
    kube_controller_manager_template_content = "${base64encode(data.template_file.kube-controller-manager.rendered)}"
    kube_dns_template_content                = "${base64encode(data.template_file.kube-dns.rendered)}"
    kube_proxy_template_content              = "${base64encode(data.template_file.kube-proxy.rendered)}"
    kube_dashboard_template_content          = "${base64encode(data.template_file.kube-dashboard.rendered)}"
    kube_rbac_content                        = "${base64encode(data.template_file.kube-rbac.rendered)}"
    kube_scheduler_template_content          = "${base64encode(data.template_file.kube-scheduler.rendered)}"
    kubelet_service_content                  = "${base64encode(data.template_file.kubelet-service.rendered)}"
    ca-pem-content                           = "${base64encode(var.root_ca_pem)}"
    api-server-key-content                   = "${base64encode(var.api_server_private_key_pem)}"
    api-server-cert-content                  = "${base64encode(var.api_server_cert_pem)}"
    api-token_auth_template_content          = "${base64encode(data.template_file.token_auth_file.rendered)}"
    docker_service_content                   = "${base64encode(data.template_file.docker-service.rendered)}"
    flannel_service_content                  = "${base64encode(data.template_file.flannel-service.rendered)}"
    cnibridge_service_content                = "${base64encode(data.template_file.cnibridge-service.rendered)}"
    cnibridge_sh_content                     = "${base64encode(data.template_file.cnibridge-sh.rendered)}"
  }
}

data "template_cloudinit_config" "master" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "bootstrap.yaml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.kube_master_cloud_init_file.rendered}"
  }
}
