output "seoul_healthcheck_id" {
  description = "서울 ALB 헬스체크 ID (Route53이 서울 서버 상태 확인용)"
  value       = aws_route53_health_check.seoul_alb.id
}

output "tokyo_healthcheck_id" {
  description = "도쿄 ALB 헬스체크 ID (Route53이 도쿄 서버 상태 확인용)"
  value       = var.enable_tokyo ? aws_route53_health_check.tokyo_alb[0].id : null
}
