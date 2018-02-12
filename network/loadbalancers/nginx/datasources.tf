data "template_file" "conf" {
  template = "${file("${path.module}/templates/nginx.conf")}"

  vars {
    servers = "${join("\n", formatlist("        server %s:443;", var.hosts))}"
    port    = "${var.listen_port}"
  }
}

data "template_file" "setup" {
  template = "${file("${path.module}/templates/setup.sh")}"

  vars {
    version = "${var.version}"
    port    = "${var.listen_port}"
  }
}

data "template_file" "clount_init" {
  template = "${file("${path.module}/templates/clount_init.yaml")}"

  vars {
    nginx_conf = "${base64gzip(data.template_file.conf.rendered)}"
  }
}
