terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Global provider for cross-region resources (e.g., dashboards in us-east-1)
provider "aws" {
  alias  = "global"
  region = "us-east-1"
}
