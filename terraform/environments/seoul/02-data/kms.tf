# KMS Key for Aurora Seoul Primary encryption
resource "aws_kms_key" "seoul_db_key" {
  description             = "KMS key for Aurora Seoul Primary"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name = local.kms_key_name
    }
  )
}

resource "aws_kms_alias" "seoul_db_key_alias" {
  name          = "alias/${local.kms_key_name}"
  target_key_id = aws_kms_key.seoul_db_key.key_id
}
