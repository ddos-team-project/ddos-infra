# Aurora Secondary Cluster (Tokyo)
module "aurora_secondary" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 9.0"

  name           = local.cluster_name
  engine         = var.engine
  engine_version = var.engine_version

  # Network 설정
  vpc_id                 = data.terraform_remote_state.network_tokyo.outputs.vpc_id
  create_db_subnet_group = true
  subnets                = data.terraform_remote_state.network_tokyo.outputs.db_subnets

  # Global Cluster 연결 (Secondary) - Seoul의 Global Cluster 참조
  global_cluster_identifier      = data.terraform_remote_state.data_seoul.outputs.global_cluster_id
  source_region                  = var.source_region
  enable_global_write_forwarding = var.enable_global_write_forwarding

  # 암호화 설정 (Tokyo KMS Key)
  storage_encrypted = true
  kms_key_id        = aws_kms_key.tokyo_db_key.arn

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
    for i in range(var.reader_instance_count) :
    "tokyo-reader-${i + 1}" => {
      identifier     = "${local.cluster_name}-reader-${i + 1}"
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
      Role = "Secondary"
    }
  )
}

module "cloudwatch_logs" {
  source = "../../../modules/cloudwatch/log-group"

  project = var.project
  env     = var.environment
  region  = var.location
  tier    = "db"

  services = ["aurora"]

  retention_in_days = 30
}
