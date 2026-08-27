output "app_url" {
  description = "Open this in a browser to see the app"
  value       = var.enable_edge ? "https://${var.domain_name}" : "http://${module.compute.alb_dns_name}"
}

output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "asg_name" {
  value = module.compute.asg_name
}

output "db_endpoint" {
  value     = module.data.db_endpoint
  sensitive = true
}

output "dashboard_url" {
  value = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${module.observability.dashboard_name}"
}

output "cloudfront_domain" {
  value = var.enable_edge ? module.edge[0].cloudfront_domain : null
}
