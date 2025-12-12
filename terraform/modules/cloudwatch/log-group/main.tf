locals {
  # 서비스별 로그 그룹 자동 생성
  service_log_groups = flatten([
    for svc in var.services : [
      {
        name = "/${var.env}/${var.project}/${var.tier}/${var.region}/${svc}/app"
        type = "app"
        svc  = svc
      }
    ]
  ])

  # 시스템 로그 그룹 자동 생성
  system_log_groups = [
    { name = "/${var.env}/${var.project}/${var.tier}/${var.region}/system/messages", type = "messages" },
    { name = "/${var.env}/${var.project}/${var.tier}/${var.region}/system/secure", type = "secure" },
    { name = "/${var.env}/${var.project}/${var.tier}/${var.region}/system/docker", type = "docker" },
    { name = "/${var.env}/${var.project}/${var.tier}/${var.region}/system/cloud-init", type = "cloud-init" },
    { name = "/${var.env}/${var.project}/${var.tier}/${var.region}/system/cwagent", type = "cwagent" },
  ]

  # 전체 로그 그룹 결합
  combined = concat(local.service_log_groups, local.system_log_groups)

  log_group_map = {
    for lg in local.combined :
    lg.name => lg
  }
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = local.log_group_map

  name              = each.key
  retention_in_days = var.retention_in_days

  tags = {
    Project   = var.project
    Env       = var.env
    Tier      = var.tier
    Region    = var.region
    Service   = lookup(each.value, "svc", each.value.type)
    ManagedBy = "terraform"
  }
}


