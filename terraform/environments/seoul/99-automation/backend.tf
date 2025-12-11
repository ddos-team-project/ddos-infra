terraform {
  backend "s3" {
    bucket         = "diehard-ddos-tf-state-lock"
    key            = "seoul/99-automation/terraform.tfstate" # 이 레이어의 상태 파일 경로
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}
