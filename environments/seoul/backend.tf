terraform {
  backend "s3" {
    bucket         = "diehard-ddos-tf-state-lock" # global에서 만든 버킷 이름
    key            = "seoul/terraform.tfstate"  # 저장될 경로 (폴더/파일명)
    region         = "ap-northeast-2"
    dynamodb_table = "terraform-lock-table"     # global에서 만든 테이블 이름
    encrypt        = true
  }
}