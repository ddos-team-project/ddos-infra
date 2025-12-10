# ALB 주소 (외부 진입점)
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

# ALB ARN (Route53/추후 WAF 연동 시 사용)
output "alb_arn" {
  value = aws_lb.this.arn
}

# App Security Group (Aurora가 허용해야 할 대상)
output "app_sg_id" {
  value = aws_security_group.app.id
}
