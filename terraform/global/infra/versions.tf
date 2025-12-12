terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# CloudFront용 ACM 인증서는 us-east-1에서만 생성 가능
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
