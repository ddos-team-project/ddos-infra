terraform {
  backend "s3" {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "tokyo/02-data/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
