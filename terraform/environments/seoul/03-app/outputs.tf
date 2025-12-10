output "healthcheck_alb_dns_name" {
  value = module.healthcheck_api_alb.alb_dns_name
}

output "healthcheck_alb_zone_id" {
  value = module.healthcheck_api_alb.alb_zone_id
}

output "healthcheck_app_sg_id" {
  value = module.healthcheck_api_asg.app_sg_id
}
