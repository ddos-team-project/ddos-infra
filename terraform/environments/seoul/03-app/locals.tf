locals {
  alb_suffix = regex("loadbalancer/(.*)", module.healthcheck_api_alb.alb_arn)[0]
  tg_suffix  = regex("targetgroup/(.*)", module.healthcheck_api_alb.target_group_arn)[0]

  name_prefix = "healthcheck-api-seoul"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  app_subnet_ids = data.terraform_remote_state.network.outputs.app_subnets
  alb_subnet_ids = data.terraform_remote_state.network.outputs.public_subnets

  alb_suffix_tokyo = var.alb_suffix_tokyo

  alb_suffixes = {
    seoul = local.alb_suffix
    tokyo = local.alb_suffix_tokyo
  }

  # IDC 설정
  idc_host_cidr = data.terraform_remote_state.network.outputs.idc_host_cidr

  # TODO: SSM/Secrets Manager로 DB 엔드포인트 주입
  db_host = try(data.terraform_remote_state.db.outputs.cluster_endpoint, null)

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

  common_tags = {
    Project   = var.project
    Env       = var.env
    Tier      = var.tier
    Region    = var.region_code # 태그는 apne2
    ManagedBy = "terraform"
    Owner     = var.owner
  }

  db_cluster_ids = {
    seoul = data.terraform_remote_state.db.outputs.cluster_id
    tokyo = data.terraform_remote_state.db_tokyo.outputs.cluster_id
  }

  synthetics_canary_url      = length(trimspace(var.synthetics_canary_url)) > 0 ? var.synthetics_canary_url : "https://${var.route53_tier1_record}/health"
  synthetics_canary_name     = "${local.name_prefix}-health-canary"
  synthetics_artifact_prefix = "s3://${var.synthetics_artifact_bucket}/synthetics/${local.name_prefix}"
}
