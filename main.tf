provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "nginx" {
  metadata {
    name = var.namespace
  }
}

data "http" "red_html" {
  url = var.red_url
}

data "http" "blue_html" {
  url = var.blue_url
}

resource "kubernetes_config_map" "red" {
  metadata {
    name      = "red-index"
    namespace = var.namespace
  }
  data = {
    "index.html" = data.http.red_html.response_body
  }
}

resource "kubernetes_config_map" "blue" {
  metadata {
    name      = "blue-index"
    namespace = var.namespace
  }
  data = {
    "index.html" = data.http.blue_html.response_body
  }
}

resource "kubernetes_deployment" "nginx_red" {
  metadata {
    name      = "nginx-red"
    namespace = var.namespace
    labels    = { app = "nginx" }
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = { app = "nginx", color = "red" }
    }
    template {
      metadata {
        labels = {
          app   = "nginx"
          color = "red"
        }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"
          port {
            container_port = 80
          }
          volume_mount {
            name       = "html"
            mount_path = "/usr/share/nginx/html"
          }
        }
        volume {
          name = "html"
          config_map {
            name = kubernetes_config_map.red.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "nginx_blue" {
  metadata {
    name      = "nginx-blue"
    namespace = var.namespace
    labels    = { app = "nginx" }
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = { app = "nginx", color = "blue" }
    }
    template {
      metadata {
        labels = {
          app   = "nginx"
          color = "blue"
        }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine"
          port {
            container_port = 80
          }
          volume_mount {
            name       = "html"
            mount_path = "/usr/share/nginx/html"
          }
        }
        volume {
          name = "html"
          config_map {
            name = kubernetes_config_map.blue.metadata[0].name
          }
        }
      }
    }
  }
}

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
  }
}

resource "kubernetes_ingress_class" "nginx" {
  metadata {
    name = var.ingress_class
  }

  spec {
    controller = "k8s.io/ingress-nginx"
  }
}

resource "kubernetes_ingress_v1" "nginx" {
  depends_on = [kubernetes_ingress_class.nginx]

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

resource "kubernetes_service_account" "ingress" {
  metadata {
    name      = "ingress-nginx"
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role" "ingress" {
  metadata {
    name = "ingress-nginx"
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "nodes", "pods", "secrets", "services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["discovery.k8s.io"]
    resources  = ["endpointslices"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions", "networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "update"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingressclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }
}


resource "kubernetes_cluster_role_binding" "ingress" {
  metadata {
    name = "ingress-nginx"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.ingress.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ingress.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_daemonset" "ingress_nginx_controller" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = var.namespace
    labels = {
      app = "ingress-nginx"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "ingress-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "ingress-nginx"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.ingress.metadata[0].name
        host_network = true

        container {
          name  = "controller"
          image = "registry.k8s.io/ingress-nginx/controller:v1.11.3"

          port {
            container_port = 80
            host_port      = 80
          }

          args = [
            "/nginx-ingress-controller",
            "--ingress-class=nginx",
            "--election-id=ingress-controller-leader"
          ]

          env {
            name  = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name  = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 10254
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }
      }
    }
  }
}

output "ingress_endpoint" {
  value = "http://${var.ingress_ip}"
}
