variable "name" {
  description = "ALB name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_subnet_ids" {
  description = "Subnets for ALB (typically public)"
  type        = list(string)
}

variable "app_port" {
  description = "Port exposed on target group"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/health"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "alb_security_group_id" {
  description = "Existing ALB security group ID (if null, module creates one)"
  type        = string
  default     = null
}
