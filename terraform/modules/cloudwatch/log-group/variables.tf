variable "project" {
  description = "프로젝트 코드 (예: ddos)"
  type        = string
}

variable "env" {
  description = "환경 이름 (예: poc, prod)"
  type        = string
}
variable "region" {
  description = "Region (seoul/tokyo)"
  type        = string
}

variable "retention_in_days" {
  description = "로그 보존 기간(일 단위)"
  type        = number
  default     = 30
}

variable "services" {
  type = list(string)
}

variable "tier" {
  type = string
}
