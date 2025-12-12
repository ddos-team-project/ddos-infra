output "iam_role_arn" {
  description = "SSM Automation Aurora 페일오버/페일백용 IAM 역할 ARN"
  value       = module.aurora_automation.iam_role_arn
}

output "iam_role_name" {
  description = "SSM Automation IAM 역할 이름"
  value       = module.aurora_automation.iam_role_name
}

output "failover_document_name" {
  description = "Aurora 페일오버 SSM Automation Document 이름"
  value       = aws_ssm_document.aurora_failover_runbook.name
}

output "failback_document_name" {
  description = "Aurora 페일백 SSM Automation Document 이름"
  value       = aws_ssm_document.aurora_failback_runbook.name
}

output "disaster_failover_document_name" {
  description = "Aurora 재해 페일오버 SSM Automation Document 이름 (Seoul 전체 장애 시)"
  value       = aws_ssm_document.aurora_disaster_failover_runbook.name
}
