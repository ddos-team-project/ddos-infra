output "ssm_automation_role_arn" {
  description = "SSM Automation Aurora 페일오버/페일백용 IAM 역할 ARN"
  value       = aws_iam_role.ssm_automation_failover_role.arn
}

output "failover_document_name" {
  description = "Aurora 페일오버 SSM Automation Document 이름"
  value       = aws_ssm_document.aurora_failover_runbook.name
}

output "failback_document_name" {
  description = "Aurora 페일백 SSM Automation Document 이름"
  value       = aws_ssm_document.aurora_failback_runbook.name
}
