# 01-network remote_state for VPC / Subnets
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "tokyo/01-network/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# 02-data remote_state for Aurora endpoint/SG
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "tokyo/02-data/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "aws_caller_identity" "current" {}
