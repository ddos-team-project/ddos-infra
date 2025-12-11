locals {
  # 리소스 이름 prefix (지역명 사용)
  name_prefix = "${var.project}-${var.environment}-${var.tier}-${var.location}"

  # 공통 태그 (Region은 코드로)
  common_tags = {
    Project   = var.project
    Env       = var.environment
    Tier      = var.tier
    Region    = var.region_code  # 태그는 apne1
    ManagedBy = "terraform"
    Owner     = var.owner
  }

  cluster_name        = var.cluster_name
  global_cluster_name = var.global_cluster_id
  kms_key_name        = "${local.name_prefix}-kms"
  db_password_ssm_path  = "/ddos/aurora/password"
}
