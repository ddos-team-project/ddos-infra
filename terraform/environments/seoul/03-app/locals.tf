locals {
  name_prefix = "healthcheck-api-seoul"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  app_subnet_ids = data.terraform_remote_state.network.outputs.app_subnets
  alb_subnet_ids = data.terraform_remote_state.network.outputs.public_subnets

  # TODO: SSM/Secrets Manager로 DB 엔드포인트 주입
  db_host = "dh-prod-db-seoul-aurora-v2.cluster-clg0eecwg923.ap-northeast-2.rds.amazonaws.com"

  ecr_repository = "dh-prod-t1-ecr-healthcheck-api"
  image_tag      = "dev"

  aws_account_id = data.aws_caller_identity.current.account_id

  image_uri = "${local.aws_account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/${local.ecr_repository}:${local.image_tag}"

  tags = {
    Project = "ddos"
    Env     = "prod"
    Region  = "seoul"
    System  = "healthcheck-api"
  }
}
