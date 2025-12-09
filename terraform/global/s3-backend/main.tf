# global/s3-backend/main.tf

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
  region = "ap-northeast-2"
}

# 1. State 파일을 저장할 S3 버킷
resource "aws_s3_bucket" "tf_state" {
  bucket = "diehard-ddos-tf-state-lock" # 전 세계 유일한 이름이어야 함
}

# 2. S3 버저닝 활성화 (실수 방지용 필수)
resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. State 잠금(Locking)을 위한 DynamoDB
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}