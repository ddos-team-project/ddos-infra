variable "region_name" {
  description = "Region name for resource naming (Seoul, Tokyo)"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "failover_runbook_content" {
  description = "Content of the failover runbook YAML file"
  type        = string
}

variable "failback_runbook_content" {
  description = "Content of the failback runbook YAML file"
  type        = string
}

variable "disaster_failover_runbook_content" {
  description = "Content of the disaster failover runbook YAML file for regional outage scenarios"
  type        = string
}

variable "db_endpoint_parameter_name" {
  description = "SSM Parameter name for DB endpoint"
  type        = string
  default     = "/ddos/aurora/cluster_endpoint"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
