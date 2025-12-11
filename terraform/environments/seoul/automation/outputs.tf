output "ssm_automation_role_arn" {
  description = "SSM Automation 페일오버용 IAM 역할 ARN"
  value       = aws_iam_role.ssm_automation_failover_role.arn
}

output "ssm_document_name" {
  description = "생성된 SSM Automation Document 이름"
  value       = aws_ssm_document.aurora_failover_runbook.name
}
