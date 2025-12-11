
locals {
  # 변환: t1 = ["api"] → {tier=t1, name=api, full=/prod/dh/t1/api}
  flattened = flatten([
    for tier, groups in var.log_groups_by_tier :
    [
      for g in groups : {
        tier = tier
        name = g
        full = "/${var.env}/${var.project}/${tier}/${g}"
      }
    ]
  ])

  log_group_map = {
    for lg in local.flattened :
    "${lg.tier}-${lg.name}" => lg
  }
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = local.log_group_map

  name              = each.value.full
  retention_in_days = var.retention_in_days

  tags = {
    Project   = var.project
    Env       = var.env
    Tier      = each.value.tier
    Service   = each.value.name
    Region    = var.region
    ManagedBy = "terraform"
  }
}


locals {
  metric_filters = flatten([
    for key, lg in local.log_group_map :
    [
      for p in var.pattern_list : {
        key         = "${key}-${p}"
        log_group   = lg.full
        metric_name = "${lg.name}-${p}-metric"
        pattern     = p
      }
    ]
  ])

  metric_filter_map = {
    for mf in local.metric_filters :
    mf.key => mf
  }
}

resource "aws_cloudwatch_log_metric_filter" "this" {
  for_each = local.metric_filter_map

  depends_on = [
    aws_cloudwatch_log_group.this
  ]

  name           = each.key
  log_group_name = each.value.log_group
  pattern        = each.value.pattern

  metric_transformation {
    name      = each.value.metric_name
    namespace = var.metric_namespace
    value     = "1"
  }
}


resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = aws_cloudwatch_log_metric_filter.this

  alarm_name        = "${each.key}-alarm"
  alarm_description = "Log metric alarm for ${each.key}"

  metric_name = each.value.metric_transformation[0].name
  namespace   = var.metric_namespace

  statistic           = "Sum"
  period              = var.period
  evaluation_periods  = var.evaluation_periods
  threshold           = var.threshold
  comparison_operator = var.comparison_operator

  alarm_actions = var.alarm_actions
  ok_actions    = var.alarm_actions

  treat_missing_data = "notBreaching"
}
