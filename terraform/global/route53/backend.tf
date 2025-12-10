terraform {
  backend "s3" {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "global/route53/terraform.tfstate"
    region         = "ap-northeast-2"
    profile        = "admin-role"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
