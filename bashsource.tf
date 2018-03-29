resource null_resource "build_source" {
  provisioner "local-exec" {
    command = "echo \"export KUBECONFIG=${path.root}/generated/kubeconfig\" > ${var.label_prefix}source.sh"
  }
}

resource null_resource "k8smaster-ad1" {
  count = "${var.k8sMasterAd1Count}"
  depends_on = [
    "module.instances-k8smaster-ad1",
  ] 

  triggers {
    master_id = "${element(module.instances-k8smaster-ad1.ids, count.index)}"
    build_source_id = "${null_resource.build_source.id}"
  }

  provisioner "local-exec" {
    command = "echo 'alias ${var.label_prefix}masterad1-${count.index}=\"ssh -i ${path.root}/generated/instances_id_rsa opc@${element(module.instances-k8smaster-ad1.public_ips, count.index)}\"' >> source.sh"
  }
}

resource null_resource "k8smaster-ad2" {
  count = "${var.k8sMasterAd2Count}"
  depends_on = [
    "module.instances-k8smaster-ad2",
  ] 

  triggers {
    master_id = "${element(module.instances-k8smaster-ad2.ids, count.index)}"
    build_source_id = "${null_resource.build_source.id}"
  }

  provisioner "local-exec" {
    command = "echo 'alias ${var.label_prefix}masterad2-${count.index}=\"ssh -i ${path.root}/generated/instances_id_rsa opc@${element(module.instances-k8smaster-ad2.public_ips, count.index)}\"' >> source.sh"
  }
}


resource null_resource "k8smaster-ad3" {
  count = "${var.k8sMasterAd3Count}"
  depends_on = [
    "module.instances-k8smaster-ad3",
  ] 

  triggers {
    master_id = "${element(module.instances-k8smaster-ad3.ids, count.index)}"
    build_source_id = "${null_resource.build_source.id}"
  }

  provisioner "local-exec" {
    command = "echo 'alias ${var.label_prefix}masterad3-${count.index}=\"ssh -i ${path.root}/generated/instances_id_rsa opc@${element(module.instances-k8smaster-ad3.public_ips, count.index)}\"' >> source.sh"
  }
}

resource null_resource "k8sworker-ad1" {
  count = "${var.k8sWorkerAd1Count}"
  depends_on = [
    "module.instances-k8sworker-ad1",
  ]

  triggers {
    worker_id = "${element(module.instances-k8sworker-ad1.ids, count.index)}"
    build_source_id = "${null_resource.build_source.id}"
  }

  provisioner "local-exec" {
    command = "echo 'alias ${var.label_prefix}workerad1-${count.index}=\"ssh -i ${path.root}/generated/instances_id_rsa opc@${element(module.instances-k8sworker-ad1.public_ips, count.index)}\"' >> source.sh"
  }
}

resource null_resource "k8sworker-ad2" {
  count = "${var.k8sWorkerAd2Count}"
  depends_on = [
    "module.instances-k8sworker-ad2",
  ] 

  triggers {
    worker_id = "${element(module.instances-k8sworker-ad2.ids, count.index)}"
    build_source_id = "${null_resource.build_source.id}"
  }

  provisioner "local-exec" {
    command = "echo 'alias ${var.label_prefix}workerad2-${count.index}=\"ssh -i ${path.root}/generated/instances_id_rsa opc@${element(module.instances-k8sworker-ad2.public_ips, count.index)}\"' >> source.sh"
  }
}


resource null_resource "k8sworker-ad3" {
  count = "${var.k8sWorkerAd3Count}"
  depends_on = [
    "module.instances-k8sworker-ad3",
  ] 

  triggers {
    master_id = "${element(module.instances-k8sworker-ad3.ids, count.index)}"
    build_source_id = "${null_resource.build_source.id}"
  }

  provisioner "local-exec" {
    command = "echo 'alias ${var.label_prefix}workerad3-${count.index}=\"ssh -i ${path.root}/generated/instances_id_rsa opc@${element(module.instances-k8sworker-ad3.public_ips, count.index)}\"' >> source.sh"
  }
}

