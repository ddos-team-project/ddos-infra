#############################################################
# 서울 리전 App 계층
# Healthcheck API Docker 컨테이너를 EC2 + ASG + ALB로 운영
# DB/Aurora 및 Networking은 Remote State 참조
#############################################################

terraform {
  required_version = ">= 1.6.0"
  backend "s3" {
    bucket = "diehard-ddos-tf-state-lock" # 🔥 실제 값
    key    = "seoul/03-app/healthcheck-api.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

#  01-network remote_state → VPC / Subnets
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/01-network/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

#  02-data remote_state → Aurora endpoint
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/02-data/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "healthcheck-api-seoul"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  # ❗ 여기 2줄이 핵심
  app_subnet_ids = data.terraform_remote_state.network.outputs.app_subnets
  alb_subnet_ids = data.terraform_remote_state.network.outputs.public_subnets

  db_host = "dh-prod-db-seoul-aurora-primary.cluster-clg0eecwg923.ap-northeast-2.rds.amazonaws.com"


  ecr_repository = "dh-prod-t1-ecr-healthcheck-api"
  image_tag      = "dev"
  image_uri      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/${local.ecr_repository}:${local.image_tag}"
}

# DB 비밀번호는 tfvars 또는 CI/CD에서 안전하게 주입
variable "aurora_app_password" {
  type      = string
  sensitive = true
  default   = ""
}

module "healthcheck_api_app" {
  source = "../../../modules/app-ec2-asg"

  name           = local.name_prefix
  vpc_id         = local.vpc_id
  app_subnet_ids = local.app_subnet_ids
  alb_subnet_ids = local.alb_subnet_ids

  aws_region = "ap-northeast-2"

  image_uri = local.image_uri

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

# 출력 → 운영/검증에 유용
output "healthcheck_alb_dns_name" {
  value = module.healthcheck_api_app.alb_dns_name
}

output "healthcheck_app_sg_id" {
  value = module.healthcheck_api_app.app_sg_id
}
