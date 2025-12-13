variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}
variable "enable_route53_tier1_record" {
  description = "tier1 Route53 record 생성 여부 (글로벌에서 관리하므로 기본 false)"
  type        = bool
  default     = false
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

variable "project" {
  description = "프로젝트 코드 (예: ddos)"
  type        = string
  default     = "ddos"
}

variable "env" {
  description = "환경 (예: prod)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "리전 (예: seoul)"
  type        = string
  default     = "seoul"
}

variable "tier" {
  description = "티어 (예: t1)"
  type        = string
  default     = "t1"
}

variable "service_name" {
  description = "서비스 이름 (예: healthcheck-api)"
  type        = string
  default     = "healthcheck-api"
}

variable "retention_in_days" {
  description = "로그 보존 일수"
  type        = number
  default     = 30
}

variable "region_code" {
  description = "Short region code (apne2, apne1)"
  type        = string
  default     = "apne2"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "devops"
}

variable "route53_healthcheck_ids" {
  description = "Route53 health check IDs map { seoul = \"...\", tokyo = \"...\" }"
  type = object({
    seoul = string
    tokyo = string
  })
  default = {
    seoul = "f6f74063-271b-44cf-b3dd-2c20d90efba6"
    tokyo = "29ee2bfd-7678-474f-b6ee-d421c9712eae"
  }
}

variable "alb_suffix_tokyo" {
  description = "ALB suffix for Tokyo (LoadBalancer dimension value, e.g. app/xxx-alb/...)"
  type        = string
  default     = "app/healthcheck-api-tokyo-alb/e96ebc5e91cc7975"
}

variable "alb_5xx_rate_threshold" {
  description = "ALB 5xx rate threshold (5xx / RequestCount). Default 5%."
  type        = number
  default     = 0.05
}

variable "alb_unhealthy_host_ratio_threshold" {
  description = "ALB UnhealthyHostCount ratio threshold (Unhealthy / (Healthy+Unhealthy)). Default 50%."
  type        = number
  default     = 0.5
}

variable "alb_request_count_floor" {
  description = "RequestCount floor for RPS drop alarm (Sum per minute). Set based on normal traffic."
  type        = number
  default     = 50
}

variable "enable_synthetics_canary" {
  description = "Whether to deploy CloudWatch Synthetics canary for /health."
  type        = bool
  default     = false
}

variable "synthetics_canary_url" {
  description = "Target URL for synthetics /health check."
  type        = string
  default     = ""
}

variable "synthetics_artifact_bucket" {
  description = "S3 bucket for synthetics artifacts (required when enable_synthetics_canary=true)."
  type        = string
  default     = ""
}

variable "synthetics_schedule_expression" {
  description = "Schedule expression for synthetics canary."
  type        = string
  default     = "rate(5 minutes)"
}

variable "alarm_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = null
}
