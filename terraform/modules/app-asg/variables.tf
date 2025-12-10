variable "name" {
  description = "App name prefix"
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
  description = "Full ECR image URI"
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
  description = "Logical region label for app"
  type        = string
  default     = "seoul"
}

variable "container_port" {
  description = "Container internal port"
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

variable "db_password" {
  description = "Aurora password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "app_security_group_id" {
  description = "Existing App security group ID (if null, module creates one)"
  type        = string
  default     = null
}

variable "alb_security_group_id" {
  description = "ALB security group ID to allow ingress from (required if creating app SG)"
  type        = string
  default     = null
}

variable "target_group_arns" {
  description = "Target group ARNs to attach to the ASG"
  type        = list(string)
}

variable "key_name" {
  type    = string
  default = null
}
