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
    master_lb          = "${var.master_lb}"
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

data "template_file" "kube-proxy" {
  template = "${file("${path.module}/manifests/kube-proxy.template.yaml")}"

  vars = {
    master_lb   = "${var.master_lb}"
    k8s_ver     = "${var.k8s_ver}"
    domain_name = "${var.domain_name}"
  }
}

data "template_file" "worker-kubeconfig" {
  template = "${file("${path.module}/manifests/worker-kubeconfig.template.yaml")}"

  vars = {
    master_lb   = "${var.master_lb}"
    k8s_ver     = "${var.k8s_ver}"
    domain_name = "${var.domain_name}"
  }
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

data "template_file" "kubelet-service" {
  template = "${file("${path.module}/scripts/kubelet.service")}"

  vars = {
    master_lb   = "${var.master_lb}"
    k8s_ver     = "${var.k8s_ver}"
    domain_name = "${var.domain_name}"
    region      = "${lower(var.region)}"
    zone        = "${lower(replace(var.availability_domain,":","-"))}"
  }
}

data "template_file" "kube_worker_cloud_init_file" {
  template = "${file("${path.module}/cloud_init/bootstrap.template.yaml")}"

  vars = {
    k8s_ver                            = "${var.k8s_ver}"
    setup_preflight_sh_content         = "${base64encode(data.template_file.setup-preflight.rendered)}"
    setup_template_sh_content          = "${base64encode(data.template_file.setup-template.rendered)}"
    kube_proxy_template_content        = "${base64encode(data.template_file.kube-proxy.rendered)}"
    worker_kubeconfig_template_content = "${base64encode(data.template_file.worker-kubeconfig.rendered)}"
    docker_service_content             = "${base64encode(data.template_file.docker-service.rendered)}"
    flannel_service_content            = "${base64encode(data.template_file.flannel-service.rendered)}"
    cnibridge_service_content          = "${base64encode(data.template_file.cnibridge-service.rendered)}"
    cnibridge_sh_content               = "${base64encode(data.template_file.cnibridge-sh.rendered)}"
    kubelet_service_content            = "${base64encode(data.template_file.kubelet-service.rendered)}"
    ca-pem-content                     = "${base64encode(var.root_ca_pem)}"
    ca-key-content                     = "${base64encode(var.root_ca_key)}"
    api-server-key-content             = "${base64encode(var.api_server_private_key_pem)}"
    api-server-cert-content            = "${base64encode(var.api_server_cert_pem)}"
  }
}

data "template_cloudinit_config" "master" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "bootstrap.yaml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.kube_worker_cloud_init_file.rendered}"
  }
}
