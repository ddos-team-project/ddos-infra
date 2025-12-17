terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

###############################
# Seoul 03-app Remote State
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
# Seoul 02-data Remote State
###############################
data "terraform_remote_state" "seoul_data" {
  backend = "s3"
  config = {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "seoul/02-data/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

###############################
# Tokyo 02-data Remote State
###############################
data "terraform_remote_state" "tokyo_data" {
  backend = "s3"
  config = {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "tokyo/02-data/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}

###############################
# Tokyo 03-app Remote State
###############################
data "terraform_remote_state" "tokyo_app" {
  backend = "s3"
  config = {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "tokyo/03-app/healthcheck-api.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}


locals {
  # Seoul
  seoul_alb_suffix = data.terraform_remote_state.seoul_app.outputs.healthcheck_alb_suffix
  seoul_asg_name   = data.terraform_remote_state.seoul_app.outputs.healthcheck_asg_name
  seoul_tg_suffix  = data.terraform_remote_state.seoul_app.outputs.healthcheck_tg_suffix

  # Tokyo
  tokyo_alb_suffix = data.terraform_remote_state.tokyo_app.outputs.healthcheck_alb_suffix
  tokyo_asg_name   = data.terraform_remote_state.tokyo_app.outputs.healthcheck_asg_name
  tokyo_tg_suffix  = data.terraform_remote_state.tokyo_app.outputs.healthcheck_tg_suffix

  # Aurora clusters
  seoul_cluster_id = try(data.terraform_remote_state.seoul_data.outputs.cluster_id, null)
  tokyo_cluster_id = try(data.terraform_remote_state.tokyo_data.outputs.cluster_id, null)

  # Route53 Health Check IDs
  seoul_healthcheck_id = var.seoul_healthcheck_id
  tokyo_healthcheck_id = var.tokyo_healthcheck_id

  # Custom metric settings
  metric_namespace        = var.metric_namespace
  metric_dimension_system = "dr"
  writer_region_primary   = var.writer_primary_region
  writer_region_secondary = var.writer_secondary_region
  writer_region_value_map = {
    primary   = var.writer_primary_value
    secondary = var.writer_secondary_value
  }
}
