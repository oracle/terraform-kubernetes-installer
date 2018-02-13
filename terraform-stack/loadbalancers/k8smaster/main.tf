resource "baremetal_load_balancer" "lb-k8smaster" {
  count          = "${var.enable == "true" ? 1 : 0}"
  shape          = "${var.shape}"
  compartment_id = "${var.compartment_ocid}"

  subnet_ids = [
    "${var.k8smaster_subnet_0_id}",
    "${var.k8smaster_subnet_1_id}",
  ]

  display_name = "${var.label_prefix}lb-k8smaster"
}

resource "baremetal_load_balancer_backendset" "lb-k8smaster-https" {
  count            = "${var.enable == "true" ? 1 : 0}"
  name             = "backendset-https"
  load_balancer_id = "${baremetal_load_balancer.lb-k8smaster.id}"
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = 443
    protocol            = "TCP"
    response_body_regex = ".*"
  }
}

resource "baremetal_load_balancer_listener" "port-https" {
  count                    = "${var.enable == "true" ? 1 : 0}"
  load_balancer_id         = "${baremetal_load_balancer.lb-k8smaster.id}"
  name                     = "port-https"
  default_backend_set_name = "${baremetal_load_balancer_backendset.lb-k8smaster-https.id}"
  port                     = 443
  protocol                 = "TCP"
}

resource "baremetal_load_balancer_backend" "k8smaster-backends-ad1" {
  count            = "${var.enable == "true" ? var.k8sMasterAd1Count : 0}"
  load_balancer_id = "${baremetal_load_balancer.lb-k8smaster.id}"
  backendset_name  = "${baremetal_load_balancer_backendset.lb-k8smaster-https.name}"
  ip_address       = "${element(var.k8smaster_ad1_private_ips, count.index)}"
  port             = "443"
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "baremetal_load_balancer_backend" "k8smaster-backends-ad2" {
  count            = "${var.enable == "true" ? var.k8sMasterAd2Count : 0}"
  load_balancer_id = "${baremetal_load_balancer.lb-k8smaster.id}"
  backendset_name  = "${baremetal_load_balancer_backendset.lb-k8smaster-https.name}"
  ip_address       = "${element(var.k8smaster_ad2_private_ips, count.index)}"
  port             = "443"
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "baremetal_load_balancer_backend" "k8smaster-backends-ad3" {
  count            = "${var.enable == "true" ? var.k8sMasterAd3Count : 0}"
  load_balancer_id = "${baremetal_load_balancer.lb-k8smaster.id}"
  backendset_name  = "${baremetal_load_balancer_backendset.lb-k8smaster-https.name}"
  ip_address       = "${element(var.k8smaster_ad3_private_ips, count.index)}"
  port             = "443"
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}