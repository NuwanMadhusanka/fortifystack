output "certificate_arn" {
  value = aws_acm_certificate_validation.this.certificate_arn
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "app_domain" {
  value = var.domain_name
}
