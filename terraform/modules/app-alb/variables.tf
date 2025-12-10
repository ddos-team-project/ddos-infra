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

variable "alb_sg_ids" {
  description = "ALB에 부착할 보안그룹 ID 목록(없으면 빈 리스트)"
  type        = list(string)
  default     = []
}
