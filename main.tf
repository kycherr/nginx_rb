provider "kubernetes" {
  config_path = "~/.kube/config"
}

data "external" "host_ips" {
  program = ["bash", "${path.module}/scripts/get_host_ips.sh"]
}

locals {
  external_ips = jsondecode(data.external.host_ips.result.external_ips)
}

module "namespace" {
  source    = "./modules/namespace"
  namespace = var.namespace
}

module "nginx_red" {
  source    = "./modules/nginx-app"
  name      = "nginx-red"
  color     = "red"
  html_url  = var.red_url
  namespace = var.namespace
  replicas  = var.replicas
}

module "nginx_blue" {
  source    = "./modules/nginx-app"
  name      = "nginx-blue"
  color     = "blue"
  html_url  = var.blue_url
  namespace = var.namespace
  replicas  = var.replicas
}

module "ingress" {
  source        = "./modules/ingress"
  namespace     = var.namespace
  ingress_class = var.ingress_class
  external_ips  = local.external_ips
}
