variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_port" {
  description = "Port the app listens on (ALB -> app)"
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port (app -> RDS)"
  type        = number
  default     = 5432
}

variable "enable_https" {
  description = "Open 443 on the ALB SG (requires a cert / domain)"
  type        = bool
  default     = false
}
