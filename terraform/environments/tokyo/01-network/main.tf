terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 도쿄 리전 Provider
# credentials의 [default] 또는 동일한 계정을 사용한다고 가정
provider "aws" {
  region = "ap-northeast-1"
}

module "network" {
  source = "../../../modules/network"

  name     = "ddos-tokyo"
  vpc_cidr = var.vpc_cidr
  subnets  = var.subnets
  tags     = var.tags

  # 지금은 IDC 연동 안 함
  enable_idc    = var.enable_idc
  enable_db_idc = var.enable_db_idc
  idc_cidr      = var.idc_cidr
  vgw_id        = var.vgw_id
}

# 편의용 출력
output "vpc_id" {
  value = module.network.vpc_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}
