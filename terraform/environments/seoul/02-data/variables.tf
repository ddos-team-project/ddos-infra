variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "dh"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "tier" {
  description = "Infrastructure tier (net, db, t1, t2)"
  type        = string
  default     = "db"
}

variable "region_code" {
  description = "Short region code (apne2, apne1)"
  type        = string
  default     = "apne2"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "devops"
}

variable "global_cluster_id" {
  description = "Global Aurora cluster identifier"
  type        = string
  default     = "dh-prod-global-rds"
}

variable "location" {
  description = "Location name (seoul, tokyo)"
  type        = string
  default     = "seoul"
}

variable "cluster_name" {
  description = "Aurora cluster name"
  type        = string
  default     = "dh-prod-db-seoul-aurora-primary"
}

variable "engine" {
  description = "Aurora engine type"
  type        = string
  default     = "aurora-mysql"
}

variable "engine_version" {
  description = "Aurora engine version"
  type        = string
  default     = "8.0.mysql_aurora.3.04.0"
}

variable "master_username" {
  description = "Master username for Aurora"
  type        = string
  sensitive   = true
}

variable "master_password" {
  description = "Master password for Aurora"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "Instance class for Aurora instances"
  type        = string
  default     = "db.r6g.large"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the database"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

variable "database_name" {
  description = "Initial database name to create"
  type        = string
  default     = "ddos_noncore"
}
