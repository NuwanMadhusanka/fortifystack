###############################################################################
# Remote state backend.
#
# 1) First run `make bootstrap` (creates the S3 bucket + DynamoDB lock table).
# 2) Copy the values it outputs into the block below and UNCOMMENT it.
# 3) Run `terraform init -migrate-state` to move local state into S3.
#
# Until then, Terraform uses local state (fine for a first apply).
###############################################################################

# terraform {
#   backend "s3" {
#     bucket         = "fortifystack-tfstate-xxxxxxxx"
#     key            = "fortifystack/dev/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "fortifystack-tf-lock"
#     encrypt        = true
#   }
# }
