resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

variable "namespace" {
  type    = string
}
