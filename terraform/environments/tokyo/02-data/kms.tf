# KMS Key for Aurora Tokyo Secondary encryption
resource "aws_kms_key" "tokyo_db_key" {
  description             = "KMS key for Aurora Tokyo Secondary"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name = local.kms_key_name
    }
  )
}

resource "aws_kms_alias" "tokyo_db_key_alias" {
  name          = "alias/${local.kms_key_name}"
  target_key_id = aws_kms_key.tokyo_db_key.key_id
}
