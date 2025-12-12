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

variable "disaster_recovery_verify_content" {
  description = "Content of disaster recovery step 1: verify runbook (Seoul)"
  type        = string
  default     = ""
}

variable "disaster_recovery_create_cluster_content" {
  description = "Content of disaster recovery step 2: create cluster runbook (Seoul)"
  type        = string
  default     = ""
}

variable "disaster_recovery_add_secondary_content" {
  description = "Content of disaster recovery step 3: add secondary runbook (Seoul)"
  type        = string
  default     = ""
}

variable "disaster_recovery_verify_replication_content" {
  description = "Content of disaster recovery step 4: verify replication runbook (Seoul)"
  type        = string
  default     = ""
}

variable "disaster_recovery_prepare_failback_content" {
  description = "Content of disaster recovery prepare failback runbook (Tokyo)"
  type        = string
  default     = ""
}

variable "disaster_recovery_recreate_global_content" {
  description = "Content of disaster recovery recreate global cluster runbook (Tokyo)"
  type        = string
  default     = ""
}
