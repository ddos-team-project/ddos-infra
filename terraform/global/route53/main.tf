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
  count   = var.enable_tokyo ? 1 : 0
  backend = "s3"
  config = {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "tokyo/03-app/healthcheck-api.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

resource "aws_route53_health_check" "seoul_alb" {
  fqdn              = data.terraform_remote_state.seoul_app.outputs.healthcheck_alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  request_interval  = 30
  failure_threshold = 3

  regions = [
    "ap-northeast-1",
    "ap-southeast-1",
    "us-west-2"
  ]

  tags = {
    Name = "seoul-alb-healthcheck"
  }
}

resource "aws_route53_health_check" "tokyo_alb" {
  count             = var.enable_tokyo ? 1 : 0
  fqdn              = data.terraform_remote_state.tokyo_app[0].outputs.healthcheck_alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  request_interval  = 30
  failure_threshold = 3

  regions = [
    "ap-northeast-2",
    "ap-southeast-1",
    "us-west-2"
  ]

  tags = {
    Name = "tokyo-alb-healthcheck"
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
  health_check_id = aws_route53_health_check.seoul_alb.id
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
  health_check_id = aws_route53_health_check.tokyo_alb[0].id
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
  health_check_id = aws_route53_health_check.seoul_alb.id
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
  health_check_id = aws_route53_health_check.tokyo_alb[0].id
}
