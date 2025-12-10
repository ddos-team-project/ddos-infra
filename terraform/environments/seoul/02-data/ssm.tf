# SSM Parameter Store for Aurora master password
resource "aws_ssm_parameter" "aurora_master_password" {
  name        = local.ssm_parameter_path
  description = "Aurora master password for Seoul Primary cluster"
  type        = "SecureString"
  value       = var.master_password
  key_id      = aws_kms_key.seoul_db_key.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-master-password"
    }
  )
}
