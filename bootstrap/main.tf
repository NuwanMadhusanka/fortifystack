###############################################################################
# FortifyStack - Remote state backend bootstrap
#
# Run this ONCE, before anything else, to create the S3 bucket + DynamoDB table
# that Terraform uses for remote state and state locking.
#
#   cd bootstrap
#   terraform init
#   terraform apply
#
# Then copy the bucket name / table name into terraform/envs/dev/backend.tf.
# This stack itself uses LOCAL state (chicken-and-egg), so keep the generated
# bootstrap/terraform.tfstate file safe (or commit it privately - it holds no
# secrets, just the bucket/table ids).
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.5" }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project = "FortifyStack"
      Owner   = var.owner
      Env     = "shared"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "owner" {
  type    = string
  default = "freelancer"
}

# Random suffix keeps the bucket name globally unique.
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "state" {
  bucket        = "fortifystack-tfstate-${random_id.suffix.hex}"
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "lock" {
  name         = "fortifystack-tf-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

output "state_bucket" {
  description = "Put this in backend.tf -> bucket"
  value       = aws_s3_bucket.state.id
}

output "lock_table" {
  description = "Put this in backend.tf -> dynamodb_table"
  value       = aws_dynamodb_table.lock.name
}

output "backend_config_snippet" {
  value = <<-EOT
    # Paste into terraform/envs/dev/backend.tf:
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.state.id}"
        key            = "fortifystack/dev/terraform.tfstate"
        region         = "${var.region}"
        dynamodb_table = "${aws_dynamodb_table.lock.name}"
        encrypt        = true
      }
    }
  EOT
}
