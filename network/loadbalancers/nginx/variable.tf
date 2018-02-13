variable "nginx_version" {}

variable "nginx_listen_port" {
  default = "6443"
}

variable "hosts" {
  type = "list"
}
