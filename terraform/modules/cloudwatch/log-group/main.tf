resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(var.log_group_names)

  name = "/${var.env}/${var.project}/${each.value}"

  retention_in_days = var.retention_in_days

  tags = {
    Project = var.project
    Env     = var.env
    Name    = each.value
  }
}