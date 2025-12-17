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

output "healthcheck_alb_suffix" {
  description = "Healthcheck API ALB suffix for CloudWatch metrics"
  value       = local.alb_suffix
}

output "healthcheck_asg_name" {
  description = "Healthcheck API ASG name"
  value       = module.healthcheck_api_asg.autoscaling_group_name
}

output "healthcheck_tg_suffix" {
  description = "서울 ALB 타겟 그룹 식별자 (CloudWatch 메트릭용)"
  value       = local.tg_suffix
}
