variable "compartment_ocid" {}
variable "vcn_id" {}

variable "label_prefix" {
  default = ""
}

# TODO Allow modules to access global variables #5480
variable "internal_ingress" {
  type = "map"

  default = {
    # OCI VCN
    orcl-VCN-CIDR = "10.0.0.0/16"

    # OCI regional networks
    orcl-Ashburn-CIDR   = "129.213.0.0/16"
    orcl-Frankfurt-CIDR = "130.61.0.0/16"
    orcl-Phoenix-CIDR   = "129.146.0.0/16"

    # Oracle Corporate networks outside OCI
    orcl-ADC-CIDR         = "137.254.7.160/27"
    orcl-ASH-CIDR         = "209.17.40.32/27"
    orcl-Brazil-CIDR      = "198.49.164.160/27"
    orcl-India-CIDR       = "196.15.23.0/27"
    orcl-Japan-CIDR       = "202.45.129.176/28"
    orcl-RMDC-CIDR        = "148.87.66.160/27"
    orcl-OCNA-CIDR        = "160.34.0.0/16"
    orcl-Seattle-CIDR     = "209.17.37.96/27"
    orcl-Singapore-CIDR   = "192.188.170.80/28"
    orcl-Singapore-CIDR-2 = "198.17.70.0/27"
    orcl-Sydney-CIDR      = "202.92.67.176/29"
    orcl-UK-CIDR          = "141.143.0.0/16"
    orcl-VPN-CIDR         = "156.151.0.0/16"
    orcl-WHQ-CIDR         = "148.87.23.0/27"
    orcl-Bozeman          = "129.157.69.40/32"
    orcl-Boulder          = "129.157.69.43/32"

    # Oracle HTTP Proxy
    orcl-WWW-Proxy-CIDR = "148.87.19.0/24"
  }
}

variable "external_ingress" {
  type = "map"

  default = {
    # Uptime Robot, https://uptimerobot.com/inc/files/ips/IPv4.txt
    # TODO https://gitlab-odx.oracle.com/sre/sauron/issues/249
    uptime-robot-CIDR-1 = "69.162.124.224/28"
    uptime-robot-CIDR-2 = "63.143.42.240/28"
    uptime-robot-IP-1   = "216.144.250.150/32"
    uptime-robot-IP-2   = "46.137.190.132/32"
    uptime-robot-IP-3   = "122.248.234.23/32"
    uptime-robot-IP-4   = "188.226.183.141/32"
    uptime-robot-IP-5   = "178.62.52.237/32"
    uptime-robot-IP-6   = "54.79.28.129/32"
    uptime-robot-IP-7   = "54.94.142.218/32"
    uptime-robot-IP-8   = "104.131.107.63/32"
    uptime-robot-IP-9   = "54.67.10.127/32"
    uptime-robot-IP-10  = "54.64.67.106/32"
    uptime-robot-IP-11  = "159.203.30.41/32"
    uptime-robot-IP-12  = "46.101.250.135/32"
    uptime-robot-IP-13  = "18.221.56.27/32"
    uptime-robot-IP-14  = "52.60.129.180/32"
    uptime-robot-IP-15  = "159.89.8.111/32"
    uptime-robot-IP-16  = "146.185.143.14/32"
    uptime-robot-IP-17  = "139.59.173.249/32"
    uptime-robot-IP-18  = "165.227.83.148/32"
    uptime-robot-IP-19  = "128.199.195.156/32"
    uptime-robot-IP-20  = "138.197.150.151/32"
    uptime-robot-IP-21  = "34.233.66.117/32"
  }
}
