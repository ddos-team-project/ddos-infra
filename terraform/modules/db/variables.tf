variable "name" {
  type        = string
  description = "Name prefix for Aurora cluster"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for DB"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "Private DB subnet IDs"
}

variable "app_sg_ids" {
  type        = list(string)
  description = "Allowed app SG for inbound 3306"
  default     = []
}

variable "engine_version" {
  type    = string
  default = "8.0.mysql_aurora.3.08.1"
}

variable "instance_class" {
  type    = string
  default = "db.r6g.large" # 테스트 환경
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type      = string
  sensitive = true
}

variable "backup_retention_days" {
  type    = number
  default = 0
}

variable "preferred_backup_window" {
  type    = string
  default = "17:00-18:00"
}

variable "tags" {
  type    = map(string)
  default = {}
}

############################
# 글로벌 클러스터 제어 변수
############################

# Primary (서울)만 true, Secondary (도쿄) false
variable "is_primary" {
  type        = bool
  description = "Whether this region is the primary in Global Aurora"
  default     = false
}

# Secondary (도쿄)에서만 사용: 서울의 Global Cluster ARN 입력
variable "global_cluster_identifier" {
  type        = string
  description = "Existing Aurora Global Cluster ID to join (used only in secondary region)"
  default     = null
}
