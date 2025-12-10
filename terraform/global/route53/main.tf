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
  profile = "admin-role"
}

###############################
# 1. Hosted Zone 조회
###############################
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

###############################
# 2. 서울 ALB 정보 로드
###############################
data "terraform_remote_state" "seoul_app" {
  backend = "s3"
  config = {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "environments/seoul/03-app/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

###############################
# 3. 도쿄 ALB 정보 로드
###############################
data "terraform_remote_state" "tokyo_app" {
  backend = "s3"
  config = {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "environments/tokyo/02-data/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

################################################################################
# 4. Tier1 Weighted (서울 80 / 도쿄 20)
################################################################################

# 서울 Weighted Record 80
resource "aws_route53_record" "tier1_seoul" {
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.api_tier1_record
  type           = "A"
  set_identifier = "seoul"

  alias {
    name                   = data.terraform_remote_state.seoul_app.outputs.alb_tier1_dns_name
    zone_id                = data.terraform_remote_state.seoul_app.outputs.alb_tier1_zone_id
    evaluate_target_health = true
  }

  weighted_routing_policy {
    weight = 80
  }
}


# 도쿄 Weighted Record 20
resource "aws_route53_record" "tier1_tokyo" {
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.api_tier1_record
  type           = "A"
  set_identifier = "tokyo"

  alias {
    name                   = data.terraform_remote_state.tokyo_app.outputs.alb_tier1_dns_name
    zone_id                = data.terraform_remote_state.tokyo_app.outputs.alb_tier1_zone_id
    evaluate_target_health = true
  }

  weighted_routing_policy {
    weight = 20
  }
}



################################################################################
# 5. Tier2 Failover (서울 PRIMARY / 도쿄 SECONDARY)
################################################################################

# 서울 PRIMARY
resource "aws_route53_record" "tier2_primary" {
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.api_tier2_record
  type           = "A"
  set_identifier = "primary"

  alias {
    name                   = data.terraform_remote_state.seoul_app.outputs.alb_tier2_dns_name
    zone_id                = data.terraform_remote_state.seoul_app.outputs.alb_tier2_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }
}



# 도쿄 SECONDARY
resource "aws_route53_record" "tier2_secondary" {
  zone_id        = data.aws_route53_zone.main.zone_id
  name           = var.api_tier2_record
  type           = "A"
  set_identifier = "secondary"

  alias {
    name                   = data.terraform_remote_state.tokyo_app.outputs.alb_tier2_dns_name
    zone_id                = data.terraform_remote_state.tokyo_app.outputs.alb_tier2_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }
}
