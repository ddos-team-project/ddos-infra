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

variable "log_groups_by_tier" {
  description = "티어(t1, t2, db)별 로그 그룹 리스트"
  type        = map(list(string))
}

variable "retention_in_days" {
  description = "로그 보존 기간(일 단위)"
  type        = number
  default     = 30
}

variable "pattern_list" {
  type        = list(string)
  description = "Metric Filter 패턴 (예: \"ERROR\")"
}

variable "metric_namespace" {
  type        = string
  description = "Metric 이름 (예: error_count)"

}


variable "period" {
  type    = number
  default = 60
}

variable "evaluation_periods" {
  type    = number
  default = 1
}

variable "threshold" {
  type    = number
  default = 5
}

variable "comparison_operator" {
  type    = string
  default = "GreaterThanOrEqualToThreshold"
}

variable "alarm_actions" {
  type    = list(string)
  default = []
}
