data "http" "html" {
  url = var.html_url
}

resource "kubernetes_config_map" "html" {
  metadata {
    name      = "${var.name}-index"
    namespace = var.namespace
  }
  data = {
    "index.html" = data.http.html.response_body
  }
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = var.name
    namespace = var.namespace
    labels    = { app = "nginx" }
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app   = "nginx"
        color = var.color
      }
    }

    template {
      metadata {
        labels = {
          app   = "nginx"
          color = var.color
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
            name = kubernetes_config_map.html.metadata[0].name
          }
        }
      }
    }
  }
}
