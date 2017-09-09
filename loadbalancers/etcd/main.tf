resource "baremetal_load_balancer" "lb-etcd" {
  shape          = "${var.shape}"
  compartment_id = "${var.compartment_ocid}"

  subnet_ids = [
    "${var.etcd_subnet_0_id}",
  ]

  display_name = "${var.label_prefix}lb-etcd"
  is_private   = true
}

resource "baremetal_load_balancer_backendset" "lb-etcd-backendset-2379" {
  name             = "lb-backendset-etcd-2379"
  load_balancer_id = "${baremetal_load_balancer.lb-etcd.id}"
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "2379"
    protocol            = "TCP"
    response_body_regex = ".*"   # FIXME: this should not be needed
  }
}

resource "baremetal_load_balancer_backendset" "lb-etcd-backendset-2380" {
  name             = "lb-backendset-etcd-2380"
  load_balancer_id = "${baremetal_load_balancer.lb-etcd.id}"
  policy           = "ROUND_ROBIN"

  health_checker {
    port                = "2380"
    protocol            = "TCP"
    response_body_regex = ".*"   # FIXME: this should not be needed
  }
}

resource "baremetal_load_balancer_listener" "port-2379" {
  load_balancer_id         = "${baremetal_load_balancer.lb-etcd.id}"
  name                     = "port-2379"
  default_backend_set_name = "${baremetal_load_balancer_backendset.lb-etcd-backendset-2379.id}"
  port                     = 2379
  protocol                 = "TCP"
}

resource "baremetal_load_balancer_listener" "port-2380" {
  load_balancer_id         = "${baremetal_load_balancer.lb-etcd.id}"
  name                     = "port-2380"
  default_backend_set_name = "${baremetal_load_balancer_backendset.lb-etcd-backendset-2380.id}"
  port                     = 2380
  protocol                 = "TCP"
}

resource "baremetal_load_balancer_backend" "etcd-2379-backends-ad1" {
  load_balancer_id = "${baremetal_load_balancer.lb-etcd.id}"
  backendset_name  = "${baremetal_load_balancer_backendset.lb-etcd-backendset-2379.name}"
  count            = "${var.etcdAd1Count}"
  ip_address       = "${element(var.etcd_ad1_private_ips, count.index)}"
  port             = "2379"
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "baremetal_load_balancer_backend" "etcd-2379-backends-ad2" {
  load_balancer_id = "${baremetal_load_balancer.lb-etcd.id}"
  backendset_name  = "${baremetal_load_balancer_backendset.lb-etcd-backendset-2379.name}"
  count            = "${var.etcdAd2Count}"
  ip_address       = "${element(var.etcd_ad2_private_ips, count.index)}"
  port             = "2379"
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "baremetal_load_balancer_backend" "etcd-2379-backends-ad3" {
  load_balancer_id = "${baremetal_load_balancer.lb-etcd.id}"
  backendset_name  = "${baremetal_load_balancer_backendset.lb-etcd-backendset-2379.name}"
  count            = "${var.etcdAd3Count}"
  ip_address       = "${element(var.etcd_ad3_private_ips, count.index)}"
  port             = "2379"
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "baremetal_load_balancer_backend" "etcd-2380-backends-ad1" {
  load_balancer_id = "${baremetal_load_balancer.lb-etcd.id}"
  backendset_name  = "${baremetal_load_balancer_backendset.lb-etcd-backendset-2380.name}"
  count            = "${var.etcdAd1Count}"
  ip_address       = "${element(var.etcd_ad1_private_ips, count.index)}"
  port             = "2380"
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "baremetal_load_balancer_backend" "etcd-2380-backends-ad2" {
  load_balancer_id = "${baremetal_load_balancer.lb-etcd.id}"
  backendset_name  = "${baremetal_load_balancer_backendset.lb-etcd-backendset-2380.name}"
  count            = "${var.etcdAd2Count}"
  ip_address       = "${element(var.etcd_ad2_private_ips, count.index)}"
  port             = "2380"
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}

resource "baremetal_load_balancer_backend" "etcd-2380-backends-ad3" {
  load_balancer_id = "${baremetal_load_balancer.lb-etcd.id}"
  backendset_name  = "${baremetal_load_balancer_backendset.lb-etcd-backendset-2380.name}"
  count            = "${var.etcdAd3Count}"
  ip_address       = "${element(var.etcd_ad3_private_ips, count.index)}"
  port             = "2380"
  backup           = false
  drain            = false
  offline          = false
  weight           = 1
}
