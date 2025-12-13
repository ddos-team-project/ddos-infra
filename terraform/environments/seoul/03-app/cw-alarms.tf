resource "aws_cloudwatch_metric_alarm" "alb_healthy_low" {
  alarm_name          = "${local.name_prefix}-alb-healthy-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 1
  period              = 60
  statistic           = "Average"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  dimensions = {
    LoadBalancer = local.alb_suffix
    TargetGroup  = local.tg_suffix
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  threshold           = 1
  period              = 60
  statistic           = "Sum"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  dimensions = {
    LoadBalancer = local.alb_suffix
    TargetGroup  = local.tg_suffix
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  alarm_name          = "${local.name_prefix}-alb-5xx-rate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = var.alb_5xx_rate_threshold
  treat_missing_data  = "notBreaching"
  alarm_description   = "ALB 5xx rate over RequestCount exceeds ${var.alb_5xx_rate_threshold * 100}%"
  metric_query {
    id = "m5xx"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions = {
        LoadBalancer = local.alb_suffix
        TargetGroup  = local.tg_suffix
      }
      period = 60
      stat   = "Sum"
    }
    return_data = false
  }

  metric_query {
    id = "req"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      dimensions = {
        LoadBalancer = local.alb_suffix
        TargetGroup  = local.tg_suffix
      }
      period = 60
      stat   = "Sum"
    }
    return_data = false
  }

  metric_query {
    id          = "rate"
    expression  = "IF(req>0,m5xx/req,0)"
    label       = "5xx rate"
    return_data = true
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_latency_p95" {
  alarm_name          = "${local.name_prefix}-alb-latency-p95"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 1.0 # 초, 필요 시 조정
  period              = 60
  extended_statistic  = "p95.0"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  dimensions = {
    LoadBalancer = local.alb_suffix
    TargetGroup  = local.tg_suffix
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_ratio" {
  alarm_name          = "${local.name_prefix}-alb-unhealthy-ratio"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = var.alb_unhealthy_host_ratio_threshold
  treat_missing_data  = "notBreaching"
  alarm_description   = "ALB UnhealthyHost ratio over total exceeds ${var.alb_unhealthy_host_ratio_threshold * 100}%"
  metric_query {
    id = "unh"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "UnHealthyHostCount"
      dimensions = {
        LoadBalancer = local.alb_suffix
        TargetGroup  = local.tg_suffix
      }
      period = 60
      stat   = "Average"
    }
    return_data = false
  }

  metric_query {
    id = "h"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HealthyHostCount"
      dimensions = {
        LoadBalancer = local.alb_suffix
        TargetGroup  = local.tg_suffix
      }
      period = 60
      stat   = "Average"
    }
    return_data = false
  }

  metric_query {
    id          = "ratio"
    expression  = "IF((h+unh)>0,unh/(h+unh),0)"
    label       = "Unhealthy ratio"
    return_data = true
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_request_drop" {
  alarm_name          = "${local.name_prefix}-alb-request-drop"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = var.alb_request_count_floor
  period              = 60
  statistic           = "Sum"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "RequestCount"
  dimensions = {
    LoadBalancer = local.alb_suffix
    TargetGroup  = local.tg_suffix
  }
  treat_missing_data = "breaching"
  alarm_description  = "ALB RequestCount fell below floor (possible traffic drop). Tune alb_request_count_floor as needed."
  alarm_actions      = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions         = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  alarm_name          = "${local.name_prefix}-ec2-statuscheck"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 0
  period              = 60
  statistic           = "Maximum"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  dimensions = {
    AutoScalingGroupName = module.healthcheck_api_asg.autoscaling_group_name
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  alarm_name          = "${local.name_prefix}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 80
  period              = 60
  statistic           = "Average"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions = {
    AutoScalingGroupName = module.healthcheck_api_asg.autoscaling_group_name
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

# Aurora replication lag (Seoul/Tokyo)
resource "aws_cloudwatch_metric_alarm" "aurora_lag_seoul" {
  alarm_name          = "${local.name_prefix}-aurora-lag-seoul"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 5
  period              = 60
  statistic           = "Average"
  namespace           = "AWS/RDS"
  metric_name         = "AuroraGlobalDBReplicationLag"
  dimensions = {
    DBClusterIdentifier = local.db_cluster_ids.seoul
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "aurora_lag_tokyo" {
  alarm_name          = "${local.name_prefix}-aurora-lag-tokyo"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 5
  period              = 60
  statistic           = "Average"
  namespace           = "AWS/RDS"
  metric_name         = "AuroraGlobalDBReplicationLag"
  dimensions = {
    DBClusterIdentifier = local.db_cluster_ids.tokyo
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

# Route53 health check alarms (Seoul/Tokyo)
resource "aws_cloudwatch_metric_alarm" "route53_hc_seoul" {
  alarm_name          = "${local.name_prefix}-route53-hc-seoul"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  statistic           = "Minimum"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  dimensions = {
    HealthCheckId = var.route53_healthcheck_ids.seoul
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "route53_hc_tokyo" {
  alarm_name          = "${local.name_prefix}-route53-hc-tokyo"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  statistic           = "Minimum"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  dimensions = {
    HealthCheckId = var.route53_healthcheck_ids.tokyo
  }
  alarm_actions = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions    = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}
