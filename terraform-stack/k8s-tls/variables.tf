# valid for 1000 days
variable "validity_period_hours" {
  default = 24000
}

variable "ca_cert" {
  description = "CA certificate in PEM format(generated if left blank)"
  default     = ""
}

variable "ca_key" {
  description = "CA private key in PEM format (generated if left blank)"
  default     = ""
}

variable "api_server_private_key" {
  description = "API Server private key in PEM format (generated if left blank)"
  default     = ""
}

variable "api_server_cert" {
  description = "API Server cert in PEM format (generated if left blank)"
  default     = ""
}

variable "common_name" {
  default = "kube-ca"
}

variable "master_ips" {
  default = []
}

variable "master_lb_public_ip" {}

variable "k8s-serviceip" {
  default = "10.21.0.1"
}