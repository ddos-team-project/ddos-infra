terraform {
  backend "s3" {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "tokyo/02-data/account-api-db.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "tokyo/01-network/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

data "terraform_remote_state" "seoul_db" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/02-data/account-api-db.tfstate"
    region = "ap-northeast-2"
  }
}

locals {
  app_sg_ids = []
}

module "account_api_db" {
  source = "../../../modules/db"

  name          = "account-api-tokyo"
  vpc_id        = data.terraform_remote_state.network.outputs.vpc_id
  db_subnet_ids = values(data.terraform_remote_state.network.outputs.private_db_subnets)
  app_sg_ids    = local.app_sg_ids

  master_username = "admin"
  master_password = "CHANGE_ME"

  is_primary                = false
  global_cluster_identifier = data.terraform_remote_state.seoul_db.outputs.global_cluster_id

  tags = {
    Project = "ddos"
    Env     = "prod"
    System  = "account-api"
    Region  = "tokyo"
  }
}
