resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx"
    namespace = var.namespace
  }

  spec {
    type = "LoadBalancer"
    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 80
    }
    external_ips = var.external_ips
  }
}

resource "kubernetes_ingress_class" "this" {
  metadata {
    name = var.ingress_class
  }

  spec {
    controller = "k8s.io/ingress-nginx"
  }
}

resource "kubernetes_ingress_v1" "this" {
  depends_on = [kubernetes_ingress_class.this]

  metadata {
    name      = "nginx-ingress"
    namespace = var.namespace
    annotations = {
      "nginx.ingress.kubernetes.io/load-balance" = "round_robin"
    }
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.nginx.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
