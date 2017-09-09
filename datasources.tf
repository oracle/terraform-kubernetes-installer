data "baremetal_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

resource "template_file" "etcd_discovery_url" {
  provisioner "local-exec" {
    command = "[ -d ${path.root}/generated ] || mkdir -p ${path.root}/generated && curl https://discovery.etcd.io/new?size=${var.etcdAd1Count + var.etcdAd2Count + var.etcdAd3Count} > ${path.root}/generated/discovery${self.id}"
  }
}
