terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket = "diehard-ddos-tf-state-lock" # ← 여기만 수정
    key    = "seoul/02-data/account-api-db.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# 01-network remote state 가져오기
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/01-network/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# App SG는 아직 없음 → 빈 값으로 초기 운영
locals {
  app_sg_ids = []
}

module "account_api_db" {
  source = "../../../modules/db"

  name = "account-api-seoul"

  vpc_id        = data.terraform_remote_state.network.outputs.vpc_id
  db_subnet_ids = values(data.terraform_remote_state.network.outputs.private_db_subnets)
  app_sg_ids    = local.app_sg_ids

  master_username = "admin"
  master_password = "CHANGE_ME" # 운영은 Secrets Manager 권장

  tags = {
    Project = "ddos"
    Env     = "prod"
    Region  = "seoul"
    System  = "account-api"
  }
}
output "global_cluster_id" {
  value = module.account_api_db.global_cluster_id
}
