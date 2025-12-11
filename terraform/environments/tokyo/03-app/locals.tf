locals {
  name_prefix = "healthcheck-api-tokyo"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  app_subnet_ids = data.terraform_remote_state.network.outputs.app_subnets
  alb_subnet_ids = data.terraform_remote_state.network.outputs.public_subnets

  # 헬스체크/읽기 위주이므로 reader 엔드포인트 사용
  db_host = try(data.terraform_remote_state.db.outputs.cluster_reader_endpoint, null)

  # TODO: 도쿄 빌드에 사용할 ECR 리포지토리/리전을 확인하세요.
  ecr_repository = "dh-prod-t1-ecr-healthcheck-api"
  image_tag      = "dev"

  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = var.aws_region

  # 도쿄 인스턴스가 서울 ECR 이미지를 직접 풀도록 리전을 ap-northeast-2로 고정
  image_uri = "${local.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${local.ecr_repository}:${local.image_tag}"

  tags = {
    Project = "ddos"
    Env     = "prod"
    Region  = "tokyo"
    System  = "healthcheck-api"
  }
}
