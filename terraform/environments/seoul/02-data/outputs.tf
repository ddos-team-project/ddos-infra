# ✅ Global Cluster 출력
output "global_cluster_id" {
  description = "Global Aurora cluster identifier"
  value       = aws_rds_global_cluster.this.id
}

output "global_cluster_arn" {
  description = "Global Aurora cluster ARN"
  value       = aws_rds_global_cluster.this.arn
}

# ✅ Primary Cluster 출력
output "cluster_id" {
  description = "Aurora cluster identifier"
  value       = module.aurora_primary.cluster_id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = module.aurora_primary.cluster_arn
}

output "cluster_endpoint" {
  description = "Aurora cluster endpoint (writer)"
  value       = module.aurora_primary.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = module.aurora_primary.cluster_reader_endpoint
}

output "cluster_port" {
  description = "Aurora cluster port"
  value       = module.aurora_primary.cluster_port
}

output "cluster_master_username" {
  description = "Aurora cluster master username"
  value       = module.aurora_primary.cluster_master_username
  sensitive   = true
}

output "db_sg_id" {
  description = "Aurora security group ID"
  value       = aws_security_group.aurora_seoul_t1.id
}

output "kms_key_id" {
  description = "KMS key ID for Aurora encryption"
  value       = aws_kms_key.seoul_db_key.id
}

output "kms_key_arn" {
  description = "KMS key ARN for Aurora encryption"
  value       = aws_kms_key.seoul_db_key.arn
}

output "ssm_parameter_name" {
  description = "SSM parameter name for master password"
  value       = aws_ssm_parameter.aurora_master_password.name
}
