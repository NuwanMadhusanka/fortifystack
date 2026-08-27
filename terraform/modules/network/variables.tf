variable "name" {
  description = "Name prefix for network resources"
  type        = string
}

variable "region" {
  description = "AWS region (used for the S3 gateway endpoint service name)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to span (>= 2 for HA)"
  type        = number
  default     = 2
  validation {
    condition     = var.az_count >= 2
    error_message = "az_count must be at least 2 for high availability."
  }
}

variable "one_nat_per_az" {
  description = "If true, one NAT gateway per AZ (prod HA). If false, a single shared NAT (cheaper, portfolio default)."
  type        = bool
  default     = false
}
