output "log_groups" {
  value = aws_cloudwatch_log_group.this
}
output "log_group_names" {
  value = [
    for lg in aws_cloudwatch_log_group.this :
    lg.name
  ]
}
output "metric_filters" {
  value = aws_cloudwatch_log_metric_filter.this
}

output "alarms" {
  value = aws_cloudwatch_metric_alarm.this
}
