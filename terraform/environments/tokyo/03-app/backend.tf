terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "tokyo/03-app/healthcheck-api.tfstate"
    region = "ap-northeast-2"
  }
}
