output "db_endpoint" {
  value = aws_db_instance.this.address
}

output "db_identifier" {
  value = aws_db_instance.this.identifier
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials"
  value       = aws_secretsmanager_secret.db.arn
}

output "db_instance_id" {
  value = aws_db_instance.this.id
}
