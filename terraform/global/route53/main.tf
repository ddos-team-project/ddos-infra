terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  # profile = "admin-role"
}

###############################
# 1. Hosted Zone 조회
###############################
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

###############################
# 2. 서울 ALB Remote State
###############################
data "terraform_remote_state" "seoul_app" {
  backend = "s3"
  config = {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "seoul/03-app/healthcheck-api.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

###############################
# 3. 도쿄 ALB Remote State (옵션)
###############################
data "terraform_remote_state" "tokyo_app" {
  count = var.enable_tokyo ? 1 : 0
  backend = "s3"
  config = {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "tokyo/03-app/healthcheck-api.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

################################################################################
# Tier1 Weighted (서울 80 / 도쿄 20)
################################################################################

resource "aws_route53_record" "tier1_seoul" {
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.api_tier1_record
  type           = "A"
  set_identifier = "seoul"

  alias {
    name                   = data.terraform_remote_state.seoul_app.outputs.healthcheck_alb_dns_name
    zone_id                = data.terraform_remote_state.seoul_app.outputs.healthcheck_alb_zone_id
    evaluate_target_health = true
  }

  weighted_routing_policy {
    weight = 80
  }
}

resource "aws_route53_record" "tier1_tokyo" {
  count          = var.enable_tokyo ? 1 : 0
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.api_tier1_record
  type           = "A"
  set_identifier = "tokyo"

  alias {
    name                   = data.terraform_remote_state.tokyo_app[0].outputs.healthcheck_alb_dns_name
    zone_id                = data.terraform_remote_state.tokyo_app[0].outputs.healthcheck_alb_zone_id
    evaluate_target_health = true
  }

  weighted_routing_policy {
    weight = 20
  }
}

################################################################################
# Tier2 Failover (서울 PRIMARY / 도쿄 SECONDARY)
################################################################################

resource "aws_route53_record" "tier2_primary" {
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.api_tier2_record
  type           = "A"
  set_identifier = "primary"

  alias {
    name                   = data.terraform_remote_state.seoul_app.outputs.healthcheck_alb_dns_name
    zone_id                = data.terraform_remote_state.seoul_app.outputs.healthcheck_alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }
}

resource "aws_route53_record" "tier2_secondary" {
  count          = var.enable_tokyo ? 1 : 0
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.api_tier2_record
  type           = "A"
  set_identifier = "secondary"

  alias {
    name                   = data.terraform_remote_state.tokyo_app[0].outputs.healthcheck_alb_dns_name
    zone_id                = data.terraform_remote_state.tokyo_app[0].outputs.healthcheck_alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }
}
