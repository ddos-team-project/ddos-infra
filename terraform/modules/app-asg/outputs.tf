output "app_sg_id" {
  value = var.app_security_group_id != null ? var.app_security_group_id : aws_security_group.app[0].id
}
