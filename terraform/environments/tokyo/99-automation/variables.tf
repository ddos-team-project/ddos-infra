variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "db_endpoint_parameter_name" {
  description = "The name of the SSM Parameter to store the DB endpoint"
  type        = string
  default     = "/ddos/aurora/cluster_endpoint"
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
  default     = "ops"
}

variable "location" {
  description = "Location identifier (e.g., seoul, tokyo)"
  type        = string
  default     = "tokyo"
}

variable "region_code" {
  description = "AWS region code for tags (e.g., apne2)"
  type        = string
  default     = "apne1"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops"
}
