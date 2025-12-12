# ========================================
# 🚫 Global Cluster 관련 코드 (데드락 문제로 주석 처리)
# ========================================
resource "aws_rds_global_cluster" "this" {
  global_cluster_identifier = "dh-prod-global-rds-v2"
  engine                    = var.engine
  engine_version            = var.engine_version
  storage_encrypted         = true
  deletion_protection       = var.deletion_protection
  lifecycle {
    prevent_destroy = false
  }
}

# 🚫 기존 Aurora Primary Cluster (데드락 문제로 주석 처리)
module "aurora_primary" {
  source         = "terraform-aws-modules/rds-aurora/aws"
  version        = "~> 9.0"
  name           = "dh-prod-db-seoul-aurora-v2"
  engine         = var.engine
  engine_version = var.engine_version
  # Network 설정
  vpc_id                 = data.terraform_remote_state.network.outputs.vpc_id
  create_db_subnet_group = true
  subnets                = data.terraform_remote_state.network.outputs.db_subnets
  # Global Cluster 연결 (Primary)
  global_cluster_identifier = aws_rds_global_cluster.this.id
  is_primary_cluster        = true
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
  create_security_group  = false
  vpc_security_group_ids = [aws_security_group.aurora_seoul_t1.id]

  # 인스턴스 설정
  instance_class = var.instance_class
  instances = {
    writer = {
      identifier     = "dh-prod-db-seoul-aurora-v2-writer"
      instance_class = var.instance_class
    }
    reader = {
      identifier     = "dh-prod-db-seoul-aurora-v2-reader"
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


module "cloudwatch_logs" {
  source = "../../../modules/cloudwatch/log-group"

  project = var.project
  env     = var.env
  region  = var.region
  tier    = "db"

  services = ["aurora"]

  retention_in_days = 30
}


