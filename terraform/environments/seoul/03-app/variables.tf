variable "aws_region" {
  description = "AWS Region"
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
  description = "Hosted zone name for Route53 (e.g. example.com). If null, Route53 record is not created."
  type        = string
  default     = null
}

variable "route53_record_name" {
  description = "Record name to point to the ALB (e.g. healthcheck.example.com). If null, Route53 record is not created."
  type        = string
  default     = null
}
