# Global Aurora Cluster (전역 컨테이너)
resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = var.global_cluster_id
  engine                    = var.engine
  engine_version            = var.engine_version
  storage_encrypted         = true
  deletion_protection       = var.deletion_protection

  lifecycle {
    prevent_destroy = false
  }
}

# Aurora Primary Cluster (Seoul)
module "aurora_primary" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 9.0"

  name           = local.cluster_name
  engine         = aws_rds_global_cluster.this.engine
  engine_version = aws_rds_global_cluster.this.engine_version

  # Network 설정
  vpc_id                 = data.terraform_remote_state.network.outputs.vpc_id
  create_db_subnet_group = true
  subnets                = data.terraform_remote_state.network.outputs.db_subnets

  # Global Cluster 연결
  global_cluster_identifier = aws_rds_global_cluster.this.id

  # 암호화 설정 (Seoul KMS Key)
  storage_encrypted = true
  kms_key_id        = aws_kms_key.seoul_db_key.arn

  # 마스터 계정 설정
  master_username             = var.master_username
  master_password             = var.master_password
  manage_master_user_password = false

  # 기본 데이터베이스 생성
  database_name = var.database_name

  # 보안 그룹 설정
  create_security_group = true
  security_group_rules = {
    ingress_app = {
      description = "Access from VPC"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # 인스턴스 설정
  instance_class = var.instance_class
  instances = {
    writer = {
      identifier     = "${local.cluster_name}-writer"
      instance_class = var.instance_class
    }
    reader = {
      identifier     = "${local.cluster_name}-reader"
      instance_class = var.instance_class
    }
  }

  # 운영 설정
  apply_immediately   = var.apply_immediately
  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  # 백업 설정
  backup_retention_period      = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  # 모니터링
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  monitoring_interval             = 60

  tags = merge(
    local.common_tags,
    {
      Name = local.cluster_name
      Role = "Primary"
    }
  )
}