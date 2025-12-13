variable "domain_name" {
  description = "Route53 퍼블릭 호스티드 존 도메인"
  type        = string
  default     = "ddos.io.kr"
}

variable "api_tier1_record" {
  description = "Tier1 API 레코드(FQDN)"
  type        = string
  default     = "tier1.ddos.io.kr"
}

variable "api_tier2_record" {
  description = "Tier2 API 레코드(FQDN)"
  type        = string
  default     = "tier2.ddos.io.kr"
}

variable "enable_tokyo" {
  description = "도쿄 리전을 활성화해 가중치/페일오버에 포함할지 여부"
  type        = bool
  default     = false
}

variable "api_tier1_wildcard_record" {
  description = "Tier1 API 와일드카드 레코드(DNS 캐시 우회 테스트용)"
  type        = string
  default     = "*.tier1.ddos.io.kr"
}
