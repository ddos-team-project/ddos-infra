variable "domain_name" {
  description = "Hosted Zone 도메인"
  type        = string
  default     = "ddos.io.kr"
}

variable "api_tier1_record" {
  description = "Tier1 API 도메인"
  type        = string
  default     = "api-tier1.ddos.io.kr"
}

variable "api_tier2_record" {
  description = "Tier2 API 도메인"
  type        = string
  default     = "api-tier2.ddos.io.kr"
}
