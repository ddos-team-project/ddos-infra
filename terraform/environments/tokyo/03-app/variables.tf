variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "enable_route53_tier1_record" {
  description = "Enable tier1 Route53 record (default false for manual control)"
  type        = bool
  default     = false
}

variable "aurora_app_password" {
  description = "Aurora app DB password (inject via tfvars/CI)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name (e.g. example.com). If null, Route53 records are skipped"
  type        = string
  default     = "ddos.io.kr"
}

variable "route53_tier1_record" {
  description = "ALB record name (e.g. healthcheck.example.com). If null, Route53 record is skipped"
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
