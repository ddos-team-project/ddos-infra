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
