variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "db_endpoint_parameter_name" {
  description = "The name of the SSM Parameter to store the DB endpoint (e.g., /app/db_endpoint)"
  type        = string
  default     = "/app/db_endpoint" # 기본값 설정
}

# common_tags에 필요한 변수들 (local.tf에서 사용)
variable "project" {
  description = "Project name"
  type        = string
  default     = "dh"
}

variable "environment" {
  description = "Deployment environment (e.g., prod, dev)"
  type        = string
  default     = "prod"
}

variable "tier" {
  description = "Tier of the application (e.g., frontend, backend, data)"
  type        = string
  default     = "automation" # 이 레이어의 티어는 automation
}

variable "location" {
  description = "Location identifier (e.g., seoul, tokyo)"
  type        = string
  default     = "seoul"
}

variable "region_code" {
  description = "AWS region code for tags (e.g., apne2)"
  type        = string
  default     = "apne2" # 서울의 리전 코드
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops"
}
