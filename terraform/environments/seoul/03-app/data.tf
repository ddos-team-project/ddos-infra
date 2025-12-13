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

data "terraform_remote_state" "db_tokyo" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "tokyo/02-data/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "aws_caller_identity" "current" {}
