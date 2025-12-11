variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
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
