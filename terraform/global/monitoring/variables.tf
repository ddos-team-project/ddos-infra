variable "metric_namespace" {
  description = "CloudWatch namespace for DR custom metrics"
  type        = string
  default     = "DR/Health"
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
