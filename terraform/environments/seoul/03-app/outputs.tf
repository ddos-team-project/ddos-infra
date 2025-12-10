output "healthcheck_alb_dns_name" {
  description = "Healthcheck API ALB DNS 이름"
  value       = module.healthcheck_api_alb.alb_dns_name
}

output "healthcheck_alb_zone_id" {
  description = "Healthcheck API ALB Zone ID"
  value       = module.healthcheck_api_alb.alb_zone_id
}

output "healthcheck_app_sg_id" {
  description = "Healthcheck API App 보안 그룹 ID"
  value       = module.healthcheck_api_asg.app_sg_id
}
