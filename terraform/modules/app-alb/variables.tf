variable "name" {
  description = "ALB 이름 접두사"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_subnet_ids" {
  description = "ALB용 서브넷 목록 (일반적으로 public)"
  type        = list(string)
}

variable "app_port" {
  description = "타겟 그룹에 노출할 포트"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "타겟 그룹 헬스체크 경로"
  type        = string
  default     = "/health"
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

variable "alb_sg_ids" {
  description = "ALB에 부착할 보안그룹 ID 목록(없으면 빈 리스트)"
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "HTTPS 리스너용 ACM 인증서 ARN (필수)"
  type        = string
}
