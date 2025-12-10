variable "name" {
  description = "App name prefix (e.g. healthcheck-api-seoul)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "app_subnet_ids" {
  description = "Subnets for EC2 (typically private-app)"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "Subnets for ALB (typically public)"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "ASG min capacity"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "ASG max capacity"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 2
}

variable "image_uri" {
  description = "Full ECR image URI (e.g. 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com/dh-prod-t1-ecr-healthcheck-api:dev)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for this app"
  type        = string
}

variable "service_name" {
  description = "Service name (SERVICE_NAME env)"
  type        = string
  default     = "ddos-healthcheck-api"
}

variable "app_env" {
  description = "Application environment (prod/stage/dev)"
  type        = string
  default     = "prod"
}

variable "region_label" {
  description = "Logical region label for app (e.g. seoul, tokyo)"
  type        = string
  default     = "seoul"
}

variable "container_port" {
  description = "Container internal port (Node app listens on)"
  type        = number
  default     = 3000
}

variable "app_port" {
  description = "Port exposed on EC2 / Target Group"
  type        = number
  default     = 8080
}

variable "db_host" {
  description = "Aurora endpoint"
  type        = string
}

variable "db_port" {
  description = "Aurora port"
  type        = number
  default     = 3306
}

variable "db_name" {
  description = "Aurora database name"
  type        = string
  default     = "ddos_noncore"
}

variable "db_user" {
  description = "Aurora user"
  type        = string
  default     = "app_admin"
}

variable "ssm_parameter_name" {
  description = "SSM Parameter Store path for DB password (e.g. /ddos/aurora/password)"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
variable "key_name" {
  type    = string
  default = null
}
