# ✅ Global Cluster 출력
output "global_cluster_id" {
  description = "Global Aurora 클러스터 ID"
  value       = aws_rds_global_cluster.this.id
}

output "global_cluster_arn" {
  description = "Global Aurora 클러스터 ARN"
  value       = aws_rds_global_cluster.this.arn
}

# ✅ Primary Cluster 출력
output "cluster_id" {
  description = "Aurora 클러스터 ID"
  value       = module.aurora_primary.cluster_id
}

output "cluster_arn" {
  description = "Aurora 클러스터 ARN"
  value       = module.aurora_primary.cluster_arn
}

output "cluster_endpoint" {
  description = "Aurora 클러스터 엔드포인트 (writer)"
  value       = module.aurora_primary.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora 클러스터 reader 엔드포인트"
  value       = module.aurora_primary.cluster_reader_endpoint
}

output "cluster_port" {
  description = "Aurora 클러스터 포트"
  value       = module.aurora_primary.cluster_port
}

output "cluster_master_username" {
  description = "Aurora 클러스터 마스터 사용자명"
  value       = module.aurora_primary.cluster_master_username
  sensitive   = true
}

output "db_sg_id" {
  description = "Aurora 보안 그룹 ID"
  value       = aws_security_group.aurora_seoul_t1.id
}

output "kms_key_id" {
  description = "Aurora 암호화용 KMS 키 ID"
  value       = aws_kms_key.seoul_db_key.id
}

output "kms_key_arn" {
  description = "Aurora 암호화용 KMS 키 ARN"
  value       = aws_kms_key.seoul_db_key.arn
}

output "ssm_parameter_name" {
  description = "마스터 패스워드 SSM 파라미터 이름"
  value       = aws_ssm_parameter.aurora_master_password.name
}
