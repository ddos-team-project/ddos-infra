output "dr_alerts_topic_arn" {
  description = "DR alerts SNS topic ARN"
  value       = aws_sns_topic.dr_alerts.arn
}

output "dr_alerts_topic_name" {
  description = "DR alerts SNS topic name"
  value       = aws_sns_topic.dr_alerts.name
}

output "email_notifier_lambda_arn" {
  description = "Email notifier Lambda function ARN"
  value       = aws_lambda_function.email_notifier.arn
}
