# ECR 이미지 서울 → 도쿄 복제 설정
resource "aws_ecr_replication_configuration" "healthcheck_api" {
  replication_configuration {
    rule {
      destination {
        region      = "ap-northeast-1"
        registry_id = data.aws_caller_identity.current.account_id
      }
    }
  }
}
