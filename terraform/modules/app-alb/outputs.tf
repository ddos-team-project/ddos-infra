output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.this.zone_id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "타겟 그룹 ARN"
  value       = aws_lb_target_group.this.arn
}

output "alb_sg_id" {
  description = "ALB 보안 그룹 ID 목록"
  value       = var.alb_sg_ids
}
