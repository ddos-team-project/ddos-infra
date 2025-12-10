locals {
  name_prefix = "healthcheck-api-seoul"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  app_subnet_ids = data.terraform_remote_state.network.outputs.app_subnets
  alb_subnet_ids = data.terraform_remote_state.network.outputs.public_subnets

  # TODO: SSM Parameter 에서 받아오기로 변경
  db_host = "dh-prod-db-seoul-aurora-primary.cluster-clg0eecwg923.ap-northeast-2.rds.amazonaws.com"

  ecr_repository = "dh-prod-t1-ecr-healthcheck-api"
  image_tag      = "dev"

  aws_account_id = data.aws_caller_identity.current.account_id

  image_uri = "${local.aws_account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/${local.ecr_repository}:${local.image_tag}"
}

module "healthcheck_api_app" {
  source = "../../../modules/app-ec2-asg"

  name           = local.name_prefix
  vpc_id         = local.vpc_id
  app_subnet_ids = local.app_subnet_ids
  alb_subnet_ids = local.alb_subnet_ids

  aws_region = var.aws_region
  image_uri  = local.image_uri

  instance_type    = "t3.medium"
  min_size         = 2
  max_size         = 6
  desired_capacity = 2


  service_name   = "ddos-healthcheck-api"
  region_label   = "seoul"
  app_env        = "prod"
  app_port       = 8080
  container_port = 3000

  db_host     = local.db_host
  db_name     = "ddos_noncore"
  db_user     = "admin"
  db_password = "SuperSecretPassword123!"

  tags = {
    Project = "ddos"
    Env     = "prod"
    Region  = "seoul"
    System  = "healthcheck-api"
  }
}

#라우터 53 연동 
variable "route53_zone_name" {
  description = "Hosted zone name for Route53 (e.g. example.com). If null, Route53 record is not created."
  type        = string
  default     = null
}

variable "route53_record_name" {
  description = "Record name to point to the ALB (e.g. healthcheck.example.com). If null, Route53 record is not created."
  type        = string
  default     = null
}

module "healthcheck_api_alb" {
  source = "../../../modules/app-alb"

  name              = local.name_prefix
  vpc_id            = local.vpc_id
  alb_subnet_ids    = local.alb_subnet_ids
  alb_sg_ids        = [aws_security_group.alb_seoul_t1.id]
  app_port          = 8080
  health_check_path = "/health"
  tags              = local.tags
}

module "healthcheck_api_asg" {
  source = "../../../modules/app-asg"

  name           = local.name_prefix
  vpc_id         = local.vpc_id
  app_subnet_ids = local.app_subnet_ids
  app_sg_ids     = [aws_security_group.app_seoul_t1.id]
  app_port       = 8080
  container_port = 3000

  image_uri  = local.image_uri
  aws_region = "ap-northeast-2"

  service_name = "ddos-healthcheck-api"
  region_label = "seoul"
  app_env      = "prod"

  db_host            = local.db_host
  db_name            = "ddos_noncore"
  db_user            = "admin"
  ssm_parameter_name = "/ddos/aurora/password"

  target_group_arns = [module.healthcheck_api_alb.target_group_arn]

  tags = local.tags
}
