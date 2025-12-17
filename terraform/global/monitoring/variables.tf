variable "metric_namespace" {
  description = "CloudWatch namespace for DR custom metrics"
  type        = string
  default     = "DR/Health"
}

variable "seoul_healthcheck_id" {
  description = "서울 ALB Route53 헬스체크 ID"
  type        = string
  default     = "f6f74063-271b-44cf-b3dd-2c20d90efba6"
}

variable "tokyo_healthcheck_id" {
  description = "도쿄 ALB Route53 헬스체크 ID"
  type        = string
  default     = "29ee2bfd-7678-474f-b6ee-d421c9712eae"
}

variable "dr_metrics_schedule" {
  description = "Schedule expression for DR writer/Route53 metric publisher"
  type        = string
  default     = "rate(5 minutes)"
}

variable "route53_zone_id" {
  description = "Hosted zone ID for active region detection"
  type        = string
  default     = ""
}

variable "route53_record_name" {
  description = "Record name (FQDN) to inspect for active region detection"
  type        = string
  default     = "tier1.ddos.io.kr"

  validation {
    condition     = length(trimspace(var.route53_record_name)) > 0
    error_message = "route53_record_name must be provided (e.g., tier1.ddos.io.kr)."
  }
}

variable "writer_primary_region" {
  description = "Primary writer region code"
  type        = string
  default     = "ap-northeast-2"
}

variable "writer_secondary_region" {
  description = "Secondary writer region code"
  type        = string
  default     = "ap-northeast-1"
}

variable "writer_primary_value" {
  description = "Metric value when writer is in primary region"
  type        = number
  default     = 0
}

variable "writer_secondary_value" {
  description = "Metric value when writer is in secondary region"
  type        = number
  default     = 1
}

variable "kakao_api_key" {
  description = "Kakao API key or access token (optional, can be set later)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "kakao_channel_id" {
  description = "Kakao channel/user id to send notifications to (optional placeholder)"
  type        = string
  default     = ""
}

variable "kakao_template_id" {
  description = "Kakao message template id (optional placeholder)"
  type        = string
  default     = ""
}

variable "kakao_api_url" {
  description = "Kakao API endpoint for sending messages"
  type        = string
  default     = "https://kapi.kakao.com"
}

variable "ses_sender" {
  description = "Verified SES sender email address"
  type        = string
  default     = ""
}

variable "ses_sender_ssm_path" {
  description = "SSM parameter name for SES sender email (overrides ses_sender if set)"
  type        = string
  default     = "/dr/email/sender"
}

variable "ses_recipients" {
  description = "List of email recipients for DR alerts"
  type        = list(string)
  default     = []
}

variable "ses_recipients_ssm_path" {
  description = "SSM parameter name for SES recipients (comma-separated, overrides ses_recipients if set)"
  type        = string
  default     = "/dr/email/recipients"
}

variable "ses_template_name" {
  description = "SES template name for DR alerts"
  type        = string
  default     = "dr-alert-template"
}

variable "ses_template_subject" {
  description = "SES template subject line"
  type        = string
  default     = "DR Alert: {{AlarmName}}"
}

variable "ses_template_html" {
  description = "SES template HTML body (Handlebars placeholders allowed)"
  type        = string
  default     = <<-EOT
    <h3>DR 알림</h3>
    <p><b>알람</b>: {{AlarmName}}</p>
    <p><b>상태</b>: {{NewStateValue}}</p>
    <p><b>설명</b>: {{AlarmDescription}}</p>
    <p><b>시간</b>: {{StateChangeTime}}</p>
    <p><b>상세</b>: {{NewStateReason}}</p>
  EOT
}
