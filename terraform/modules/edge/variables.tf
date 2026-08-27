variable "name" { type = string }

variable "domain_name" {
  description = "FQDN to serve the app on, e.g. app.example.com"
  type        = string
}

variable "hosted_zone_name" {
  description = "Existing Route53 public hosted zone, e.g. example.com"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB (CloudFront origin)"
  type        = string
}

variable "rate_limit" {
  description = "WAF rate-based rule: max requests per 5 min per IP"
  type        = number
  default     = 2000
}
