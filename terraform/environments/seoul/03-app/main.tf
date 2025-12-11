module "healthcheck_api_alb" {
  source = "../../../modules/app-alb"

  name              = local.name_prefix
  vpc_id            = local.vpc_id
  alb_subnet_ids    = local.alb_subnet_ids
  alb_sg_ids        = [aws_security_group.alb_seoul_t1.id]
  app_port          = 8080
  health_check_path = "/health"
  tags              = local.tags
}

module "healthcheck_api_asg" {
  source = "../../../modules/app-asg"

  name           = local.name_prefix
  vpc_id         = local.vpc_id
  app_subnet_ids = local.app_subnet_ids
  app_sg_ids     = [aws_security_group.app_seoul_t1.id]
  app_port       = 8080
  container_port = 3000

  image_uri  = local.image_uri
  aws_region = "ap-northeast-2"

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
