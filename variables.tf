variable "namespace" {
  default = "test-nginx"
}

variable "replicas" {
  default = 1
}

variable "red_url" {
  default = "https://raw.githubusercontent.com/kycherr/nginx_rb/refs/heads/main/red.html"
}

variable "blue_url" {
  default = "https://raw.githubusercontent.com/kycherr/nginx_rb/refs/heads/main/blue.html"
}

variable "ingress_class" {
  default = "nginx"
}

variable "ingress_ip" {
  default = "192.168.66.120"
}
