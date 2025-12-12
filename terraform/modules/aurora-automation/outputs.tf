output "iam_role_arn" {
  description = "ARN of the SSM Automation IAM role"
  value       = aws_iam_role.ssm_automation_role.arn
}

output "iam_role_name" {
  description = "Name of the SSM Automation IAM role"
  value       = aws_iam_role.ssm_automation_role.name
}

output "failover_document_name" {
  description = "Name of the failover SSM document"
  value       = aws_ssm_document.aurora_failover_runbook.name
}

output "failback_document_name" {
  description = "Name of the failback SSM document"
  value       = aws_ssm_document.aurora_failback_runbook.name
}

output "failover_document_arn" {
  description = "ARN of the failover SSM document"
  value       = aws_ssm_document.aurora_failover_runbook.arn
}

output "failback_document_arn" {
  description = "ARN of the failback SSM document"
  value       = aws_ssm_document.aurora_failback_runbook.arn
}

output "disaster_recovery_verify_document_name" {
  description = "Name of disaster recovery verify SSM document"
  value       = try(aws_ssm_document.disaster_recovery_verify[0].name, "")
}

output "disaster_recovery_create_cluster_document_name" {
  description = "Name of disaster recovery create cluster SSM document"
  value       = try(aws_ssm_document.disaster_recovery_create_cluster[0].name, "")
}

output "disaster_recovery_add_secondary_document_name" {
  description = "Name of disaster recovery add secondary SSM document"
  value       = try(aws_ssm_document.disaster_recovery_add_secondary[0].name, "")
}

output "disaster_recovery_verify_replication_document_name" {
  description = "Name of disaster recovery verify replication SSM document"
  value       = try(aws_ssm_document.disaster_recovery_verify_replication[0].name, "")
}

output "disaster_recovery_prepare_failback_document_name" {
  description = "Name of disaster recovery prepare failback SSM document (Tokyo)"
  value       = try(aws_ssm_document.disaster_recovery_prepare_failback[0].name, "")
}

output "disaster_recovery_recreate_global_document_name" {
  description = "Name of disaster recovery recreate global SSM document (Tokyo)"
  value       = try(aws_ssm_document.disaster_recovery_recreate_global[0].name, "")
}
