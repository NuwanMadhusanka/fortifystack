variable "project" {
  type    = string
  default = "fortifystack"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "owner" {
  type    = string
  default = "nuwan"
}

variable "alarm_email" {
  description = "nmadhusanka755@gmail.com"
  type        = string
  default     = null
}

# ---- App tier ----
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

variable "app_port" {
  type    = number
  default = 8080
}

# ---- Network ----
variable "az_count" {
  type    = number
  default = 2
}

variable "one_nat_per_az" {
  description = "One NAT gateway per AZ (prod-grade egress HA). Default false = single shared NAT (cheaper)."
  type        = bool
  default     = false
}

# ---- Data ----
variable "multi_az" {
  description = "RDS Multi-AZ standby (true = provable failover, ~2x DB cost)"
  type        = bool
  default     = false
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

# ---- Edge (advanced / optional) ----
variable "enable_edge" {
  description = "Provision CloudFront + WAF + ACM + Route53 (requires a domain in Route53)"
  type        = bool
  default     = false
}

variable "domain_name" {
  type    = string
  default = null
}

variable "hosted_zone_name" {
  type    = string
  default = null
}
