output "app_sg_id" {
  description = "App 보안 그룹 ID (app_sg_ids의 첫 번째 항목)"
  value       = length(var.app_sg_ids) > 0 ? var.app_sg_ids[0] : null
}
output "autoscaling_group_name" {
  description = "Name of the created Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

