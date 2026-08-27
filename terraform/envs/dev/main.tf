###############################################################################
# FortifyStack - dev environment. Wires the modules into the full 3-tier stack.
###############################################################################

locals {
  name = var.project
}

module "network" {
  source         = "../../modules/network"
  name           = local.name
  region         = var.region
  az_count       = var.az_count
  one_nat_per_az = var.one_nat_per_az
}

module "security" {
  source       = "../../modules/security"
  name         = local.name
  vpc_id       = module.network.vpc_id
  app_port     = var.app_port
  db_port      = 5432
  enable_https = false # TLS is terminated at CloudFront when edge is enabled
}

module "data" {
  source          = "../../modules/data"
  name            = local.name
  data_subnet_ids = module.network.data_subnet_ids
  rds_sg_id       = module.security.rds_sg_id
  instance_class  = var.db_instance_class
  multi_az        = var.multi_az
}

module "compute" {
  source            = "../../modules/compute"
  name              = local.name
  region            = var.region
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  app_subnet_ids    = module.network.app_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  app_sg_id         = module.security.app_sg_id
  secret_arn        = module.data.secret_arn
  app_source        = file("${path.module}/../../../app/app.py")
  app_port          = var.app_port
  instance_type     = var.instance_type
  min_size          = var.min_size
  max_size          = var.max_size
  desired_capacity  = var.desired_capacity
}

module "observability" {
  source                  = "../../modules/observability"
  name                    = local.name
  region                  = var.region
  alb_arn_suffix          = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix
  asg_name                = module.compute.asg_name
  db_instance_id          = module.data.db_instance_id
  alarm_email             = var.alarm_email
}

# ---- Advanced edge tier (optional) ----
module "edge" {
  count            = var.enable_edge ? 1 : 0
  source           = "../../modules/edge"
  name             = local.name
  domain_name      = var.domain_name
  hosted_zone_name = var.hosted_zone_name
  alb_dns_name     = module.compute.alb_dns_name
}
