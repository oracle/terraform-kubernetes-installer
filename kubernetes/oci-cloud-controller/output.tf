output "cloud-provider-yaml" {
  value = "${data.template_file.cloud-provider-yaml.rendered}"
}
