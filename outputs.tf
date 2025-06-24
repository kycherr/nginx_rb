output "ingress_url" {
  description = "Main Ip"
  value       = "http://${local.external_ips[0]}"
}

output "all_external_ips" {
  description = "All ip`s"
  value       = local.external_ips
}
