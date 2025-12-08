variable "project" {
  description = "프로젝트 코드 (예: ddos)"
  type        = string
}

variable "env" {
  description = "환경 이름 (예: poc, prod)"
  type        = string
}

variable "log_group_names" {
  description = "생성할 로그 그룹 이름 뒤쪽 목록 (예: [\"healthcheck-app\"])"
  type        = list(string)
}

variable "retention_in_days" {
  description = "로그 보존 기간(일 단위)"
  type        = number
  default     = 30
}