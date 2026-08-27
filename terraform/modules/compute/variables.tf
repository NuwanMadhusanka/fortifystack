variable "name" { type = string }
variable "region" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "app_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "app_sg_id" { type = string }
variable "secret_arn" { type = string }

variable "app_source" {
  description = "Contents of app.py, injected into user-data (base64) at launch"
  type        = string
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "cpu_target" {
  description = "Target average CPU % for autoscaling"
  type        = number
  default     = 50
}

variable "enable_request_scaling" {
  type    = bool
  default = false
}

variable "requests_per_target" {
  type    = number
  default = 1000
}

variable "enable_https" {
  type    = bool
  default = false
}

variable "certificate_arn" {
  description = "ACM cert ARN (required when enable_https = true)"
  type        = string
  default     = null
}
