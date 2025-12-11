locals {
  # 리소스 이름 prefix (지역명 사용)
  name_prefix = "${var.project}-${var.environment}-${var.tier}-${var.location}"

  # 공통 태그
  common_tags = {
    Project   = var.project
    Env       = var.environment
    Tier      = var.tier
    Region    = var.region_code
    ManagedBy = "terraform"
    Owner     = var.owner
  }
}
