variable "domain_name" {
  description = "ACM 인증서를 발급할 도메인 이름"
  type        = string
}

variable "route53_zone_id" {
  description = "DNS 검증용 Route53 호스팅 존 ID"
  type        = string
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

variable "subject_alternative_names" {
  description = "추가 도메인 (SAN)"
  type        = list(string)
  default     = []
}
