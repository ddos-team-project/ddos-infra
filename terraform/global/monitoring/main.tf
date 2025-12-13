terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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

  # Tokyo
  tokyo_alb_suffix = data.terraform_remote_state.tokyo_app.outputs.healthcheck_alb_suffix
  tokyo_asg_name   = data.terraform_remote_state.tokyo_app.outputs.healthcheck_asg_name
}
