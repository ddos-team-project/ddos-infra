<<<<<<< HEAD
#############################################################
# 서울 리전 App 계층 (ALB + ASG 분리 모듈 사용)
#############################################################

terraform {
  required_version = ">= 1.6.0"
  backend "s3" {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/03-app/healthcheck-api.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# 01-network remote_state → VPC / Subnets
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/01-network/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# 02-data remote_state → Aurora endpoint
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/02-data/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "aws_caller_identity" "current" {}

=======
>>>>>>> 506b52d (refactor: 서울 리전 app 리팩토링)
locals {
  name_prefix = "healthcheck-api-seoul"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  app_subnet_ids = data.terraform_remote_state.network.outputs.app_subnets
  alb_subnet_ids = data.terraform_remote_state.network.outputs.public_subnets

<<<<<<< HEAD
  db_host = "dh-prod-db-seoul-aurora-v2.cluster-clg0eecwg923.ap-northeast-2.rds.amazonaws.com"
=======
  # TODO: SSM Parameter 에서 받아오기로 변경
  db_host = "dh-prod-db-seoul-aurora-primary.cluster-clg0eecwg923.ap-northeast-2.rds.amazonaws.com"
>>>>>>> 3a85f1d (refactor: 서울 리전 app 리팩토링)

  ecr_repository = "dh-prod-t1-ecr-healthcheck-api"
  image_tag      = "dev"
<<<<<<< HEAD
  image_uri      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/${local.ecr_repository}:${local.image_tag}"
=======
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
>>>>>>> 506b52d (refactor: 서울 리전 app 리팩토링)

  tags = {
    Project = "ddos"
    Env     = "prod"
    Region  = "seoul"
    System  = "healthcheck-api"
  }
}
<<<<<<< HEAD
=======

<<<<<<< HEAD
# DB 비밀번호는 tfvars 또는 CI/CD 시크릿으로 주입 권장 (현재 기본값만 정의)
variable "aurora_app_password" {
  type      = string
  sensitive = true
  default   = ""
}
>>>>>>> 3a85f1d (refactor: 서울 리전 app 리팩토링)
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
  app_port          = 8080
  health_check_path = "/health"
  tags              = local.tags
}

module "healthcheck_api_asg" {
  source = "../../../modules/app-asg"

  name           = local.name_prefix
  vpc_id         = local.vpc_id
  app_subnet_ids = local.app_subnet_ids
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

  alb_security_group_id = module.healthcheck_api_alb.alb_sg_id
  target_group_arns     = [module.healthcheck_api_alb.target_group_arn]

  tags = local.tags
}
#라우터
data "aws_route53_zone" "root" {
  count        = var.route53_zone_name != null ? 1 : 0
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "healthcheck" {
  count   = var.route53_zone_name != null && var.route53_record_name != null ? 1 : 0
  zone_id = data.aws_route53_zone.root[0].zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = module.healthcheck_api_alb.alb_dns_name
    zone_id                = module.healthcheck_api_alb.alb_zone_id
    evaluate_target_health = true
  }
}

output "healthcheck_alb_dns_name" {
  value = module.healthcheck_api_alb.alb_dns_name
}

output "healthcheck_app_sg_id" {
  value = module.healthcheck_api_asg.app_sg_id
}
=======
>>>>>>> 506b52d (refactor: 서울 리전 app 리팩토링)
