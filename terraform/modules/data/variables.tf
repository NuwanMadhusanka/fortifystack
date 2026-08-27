variable "name" { type = string }
variable "data_subnet_ids" { type = list(string) }
variable "rds_sg_id" { type = string }

variable "engine_version" {
  type    = string
  default = "16.4"
}

variable "instance_class" {
  description = "db.t4g.micro is Graviton + free-tier-eligible-ish and cheap"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "db_name" {
  type    = string
  default = "fortifystack"
}

variable "db_username" {
  type    = string
  default = "appuser"
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "multi_az" {
  description = "Multi-AZ standby (set true to demonstrate automatic failover)"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "skip_final_snapshot" {
  type    = bool
  default = true
}

variable "performance_insights" {
  type    = bool
  default = false
}
