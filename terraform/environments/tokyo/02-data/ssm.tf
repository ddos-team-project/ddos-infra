# SSM Parameter Store for Aurora master password (Tokyo)
resource "aws_ssm_parameter" "aurora_master_password" {
  name        = local.ssm_parameter_path
  description = "Aurora master password for Tokyo secondary cluster"
  type        = "SecureString"
  value       = var.master_password
  key_id      = aws_kms_key.tokyo_db_key.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-master-password"
    }
  )
}
