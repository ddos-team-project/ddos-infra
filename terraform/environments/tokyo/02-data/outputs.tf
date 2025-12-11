output "kms_key_id" {
  description = "KMS key ID for Aurora encryption"
  value       = aws_kms_key.tokyo_db_key.id
}

output "kms_key_arn" {
  description = "KMS key ARN for Aurora encryption"
  value       = aws_kms_key.tokyo_db_key.arn
}

output "cluster_id" {
  description = "Aurora cluster identifier"
  value       = module.aurora_secondary.cluster_id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = module.aurora_secondary.cluster_arn
}

output "cluster_endpoint" {
  description = "Aurora cluster endpoint (writer)"
  value       = module.aurora_secondary.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = module.aurora_secondary.cluster_reader_endpoint
}

output "cluster_port" {
  description = "Aurora cluster port"
  value       = module.aurora_secondary.cluster_port
}

output "security_group_id" {
  description = "Aurora security group ID"
  value       = module.aurora_secondary.security_group_id
}

output "db_password_ssm_path" {
  description = "마스터 패스워드 SSM 파라미터 이름"
  value       = aws_ssm_parameter.aurora_master_password.name
}

output "cluster_endpoint_ssm_path" {
  description = "클러스터 엔드포인트 SSM 파라미터 이름"
  value       = aws_ssm_parameter.aurora_cluster_endpoint.name
}

output "cluster_reader_endpoint_ssm_path" {
  description = "클러스터 리더 엔드포인트 SSM 파라미터 이름"
  value       = aws_ssm_parameter.aurora_cluster_reader_endpoint.name
}
