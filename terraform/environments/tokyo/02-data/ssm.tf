# SSM Parameter Store for Aurora master password (Tokyo)
resource "aws_ssm_parameter" "aurora_master_password" {
  name        = local.db_password_ssm_path
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

# SSM Parameter Store for Aurora cluster endpoint (writer)
resource "aws_ssm_parameter" "aurora_cluster_endpoint" {
  name        = "/ddos/aurora/cluster_endpoint"
  description = "Aurora cluster endpoint (writer) for Tokyo Secondary"
  type        = "String"
  value       = module.aurora_secondary.cluster_endpoint

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cluster-endpoint"
    }
  )
}

# SSM Parameter Store for Aurora cluster reader endpoint
resource "aws_ssm_parameter" "aurora_cluster_reader_endpoint" {
  name        = "/ddos/aurora/cluster_reader_endpoint"
  description = "Aurora cluster reader endpoint for Tokyo Secondary"
  type        = "String"
  value       = module.aurora_secondary.cluster_reader_endpoint

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cluster-reader-endpoint"
    }
  )
}
