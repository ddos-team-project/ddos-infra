variable "domain_name" {
  description = "Route53 호스티드 존 도메인"
  type        = string
  default     = "ddos.io.kr"
}

variable "subdomain" {
  description = "서브도메인"
  type        = string
  default     = "infra"
}

variable "environment" {
  description = "환경 (prod/dev)"
  type        = string
  default     = "prod"
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default = {
    Project     = "ddos-infra-test"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
