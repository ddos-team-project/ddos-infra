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
  value       = module.aurora_automation.failover_document_name
}

output "failback_document_name" {
  description = "Aurora 페일백 SSM Automation Document 이름"
  value       = module.aurora_automation.failback_document_name
}
