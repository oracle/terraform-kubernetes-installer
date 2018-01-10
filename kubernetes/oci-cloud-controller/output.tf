output "oci-cloud-controller-manifest" {
  value = "${data.http.oci-cloud-controller-manifest.body}"
}

output "oci-cloud-controller-rbac" {
  value = "${data.http.oci-cloud-controller-rbac.body}"
}

output "cloud-provider-yaml" {
  value = "${data.template_file.cloud-provider-yaml.rendered}"
}


