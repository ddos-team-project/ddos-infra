output "iam_role_arn" {
  description = "ARN of the SSM Automation IAM role for Aurora runbooks"
  value       = aws_iam_role.ssm_automation_role.arn
}

output "iam_role_name" {
  description = "Name of the SSM Automation IAM role for Aurora runbooks"
  value       = aws_iam_role.ssm_automation_role.name
}
