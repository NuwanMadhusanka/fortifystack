variable "name" { type = string }
variable "region" { type = string }
variable "alb_arn_suffix" { type = string }
variable "target_group_arn_suffix" { type = string }
variable "asg_name" { type = string }
variable "db_instance_id" { type = string }

variable "alarm_email" {
  description = "Email to receive alarm notifications (null = no subscription)"
  type        = string
  default     = null
}
