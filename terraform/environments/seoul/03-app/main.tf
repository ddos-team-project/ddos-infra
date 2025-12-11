module "tier1_acm_certificate" {
  source = "../../../modules/acm-certificate"

  domain_name     = var.route53_tier1_record
  route53_zone_id = data.aws_route53_zone.root[0].zone_id
  tags            = local.tags
}

module "healthcheck_api_alb" {
  source = "../../../modules/app-alb"

  name              = local.name_prefix
  vpc_id            = local.vpc_id
  alb_subnet_ids    = local.alb_subnet_ids
  alb_sg_ids        = [aws_security_group.alb_seoul_t1.id]
  app_port          = 8080
  health_check_path = "/health"
  certificate_arn   = module.tier1_acm_certificate.certificate_arn
  tags              = local.tags
}

module "healthcheck_api_asg" {
  source = "../../../modules/app-asg"

  name           = local.name_prefix
  vpc_id         = local.vpc_id
  app_subnet_ids = local.app_subnet_ids

  app_sg_ids = [aws_security_group.app_seoul_t1.id]

  app_port       = 8080
  container_port = 3000


  image_uri  = local.image_uri
  aws_region = "ap-northeast-2"
  db_host            = local.db_host
  db_name            = "ddos_noncore"
  db_user            = "admin"
  ssm_parameter_name = "/ddos/aurora/password"

  cwagent_ssm_name = local.cwagent_ssm_path

  #Metadata for log templating
  env     = "prod"
  project = "ddos"
  tier    = "t1"
  region  = "seoul"


  service_name = "ddos-healthcheck-api"
  region_label = "seoul"
  app_env      = "prod"

  db_host            = local.db_host
  db_name            = "ddos_noncore"
  db_user            = "admin"
  ssm_parameter_name = "/ddos/aurora/password"

  target_group_arns = [module.healthcheck_api_alb.target_group_arn]

  tags = local.tags
}
