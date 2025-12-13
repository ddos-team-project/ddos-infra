variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-1"
}

variable "enable_route53_tier1_record" {
  description = "tier1 Route53 record 생성 여부 (글로벌에서 관리하려고 기본 false)"
  type        = bool
  default     = false
}

variable "aurora_app_password" {
  description = "Aurora 앱계정 비밀번호 (tfvars/CI에서 주입)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "route53_zone_name" {
  description = "Route53 호스팅존 이름 (예: example.com). null이면 Route53 생성을 활성 호출 안 함"
  type        = string
  default     = "ddos.io.kr"
}

variable "route53_tier1_record" {
  description = "ALB에 걸릴 도메인 이름 (예: healthcheck.example.com). null이면 Route53 생성을 활성 호출 안 함"
  type        = string
  default     = "tier1.ddos.io.kr"
}

variable "project" {
  description = "Project code (e.g. ddos)"
  type        = string
  default     = "ddos"
}

variable "env" {
  description = "Environment (e.g. prod)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "Logical region name"
  type        = string
  default     = "tokyo"
}

variable "tier" {
  description = "Tier (e.g. t1)"
  type        = string
  default     = "t1"
}

variable "service_name" {
  description = "Service name (e.g. healthcheck-api)"
  type        = string
  default     = "healthcheck-api"
}

variable "retention_in_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "region_code" {
  description = "Short region code (apne2, apne1)"
  type        = string
  default     = "apne1"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "devops"
}

variable "alarm_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = null
}
