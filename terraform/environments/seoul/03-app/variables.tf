variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "aurora_app_password" {
  description = "Aurora 앱 계정 비밀번호 (tfvars/CI에서 주입)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "route53_zone_name" {
  description = "Route53 호스팅 존 이름 (예: example.com). null이면 Route53 레코드 생성 안함"
  type        = string
  default     = "ddos.io.kr"
}

variable "route53_tier1_record" {
  description = "ALB를 가리킬 레코드 이름 (예: healthcheck.example.com). null이면 Route53 레코드 생성 안함"
  type        = string
  default     = "tier1.ddos.io.kr"
}
