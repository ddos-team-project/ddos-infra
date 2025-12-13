resource "aws_cloudwatch_dashboard" "dr_failover_summary" {
  provider       = aws.global
  dashboard_name = "DR-Failover-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0, y = 0, width = 24, height = 6,
        properties = {
          title  = "Service Health Status"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", var.route53_healthcheck_ids.seoul],
            [".", "HealthCheckStatus", "HealthCheckId", var.route53_healthcheck_ids.tokyo]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 6, width = 12, height = 6,
        properties = {
          title  = "Seoul Error Rate (%)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.seoul, { "id" : "m5xx", "stat" : "Sum", "visible" : false }],
            [".", "RequestCount", ".", ".", { "id" : "req", "stat" : "Sum", "visible" : false }],
            [{ "expression" : "IF(req>0,(m5xx/req)*100,0)", "label" : "Error rate (%)", "id" : "rate" }]
          ]
          period = 60
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type = "metric",
        x    = 12, y = 6, width = 12, height = 6,
        properties = {
          title  = "Tokyo Error Rate (%)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.tokyo, { "id" : "m5xx", "stat" : "Sum", "region" : "ap-northeast-1", "visible" : false }],
            [".", "RequestCount", ".", ".", { "id" : "req", "stat" : "Sum", "region" : "ap-northeast-1", "visible" : false }],
            [{ "expression" : "IF(req>0,(m5xx/req)*100,0)", "label" : "Error rate (%)", "id" : "rate" }]
          ]
          period = 60
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type = "metric",
        x    = 0, y = 12, width = 12, height = 6,
        properties = {
          title  = "Seoul Instance Health (%)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffix, { "id" : "unh", "stat" : "Average", "visible" : false }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffix, { "id" : "h", "stat" : "Average", "visible" : false }],
            [{ "expression" : "IF((h+unh)>0,(h/(h+unh))*100,0)", "label" : "Health (%)", "id" : "ratio" }]
          ]
          period = 60
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type = "metric",
        x    = 12, y = 12, width = 12, height = 6,
        properties = {
          title  = "Tokyo Instance Health (%)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", local.alb_suffixes.tokyo, "TargetGroup", local.tg_suffix, { "id" : "unh", "stat" : "Average", "region" : "ap-northeast-1", "visible" : false }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.tokyo, "TargetGroup", local.tg_suffix, { "id" : "h", "stat" : "Average", "region" : "ap-northeast-1", "visible" : false }],
            [{ "expression" : "IF((h+unh)>0,(h/(h+unh))*100,0)", "label" : "Health (%)", "id" : "ratio" }]
          ]
          period = 60
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type = "metric",
        x    = 0, y = 18, width = 24, height = 6,
        properties = {
          title  = "Response Time (P95)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.seoul, { "stat" : "p95" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.tokyo, { "region" : "ap-northeast-1", "stat" : "p95" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 24, width = 24, height = 4,
        properties = {
          title  = "Traffic Volume (RPS)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_suffixes.seoul],
            [".", "RequestCount", "LoadBalancer", local.alb_suffixes.tokyo, { "region" : "ap-northeast-1" }]
          ]
          period = 60
        }
      }
    ]
  })
}

resource "aws_cloudwatch_dashboard" "dr_failover_detail" {
  dashboard_name = "DR-Failover-Detail"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0, y = 0, width = 12, height = 6,
        properties = {
          title  = "ALB 5xx & p95 Latency (Seoul)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.seoul],
            [".", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.seoul, { "stat" : "p95" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 0, width = 12, height = 6,
        properties = {
          title  = "EC2 CPU/Status (Seoul)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name],
            ["AWS/EC2", "StatusCheckFailed", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 6, width = 12, height = 6,
        properties = {
          title  = "ALB 5xx & p95 Latency (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.tokyo, { "region" : "ap-northeast-1" }],
            [".", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.tokyo, { "region" : "ap-northeast-1", "stat" : "p95" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 6, width = 12, height = 6,
        properties = {
          title  = "EC2 CPU/Status (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "healthcheck-api-tokyo-asg"],
            ["AWS/EC2", "StatusCheckFailed", "AutoScalingGroupName", "healthcheck-api-tokyo-asg"]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 12, width = 12, height = 6,
        properties = {
          title  = "Aurora Lag (Seoul/Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/RDS", "AuroraGlobalDBReplicationLag", "DBClusterIdentifier", local.db_cluster_ids.seoul],
            [".", "AuroraGlobalDBReplicationLag", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 12, width = 12, height = 6,
        properties = {
          title  = "Aurora Connections / FreeableMemory"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", local.db_cluster_ids.seoul],
            [".", "FreeableMemory", "DBClusterIdentifier", local.db_cluster_ids.seoul],
            [".", "DatabaseConnections", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1" }],
            [".", "FreeableMemory", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 18, width = 12, height = 6,
        properties = {
          title  = "Aurora Latency (Read/Write)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBClusterIdentifier", local.db_cluster_ids.seoul],
            [".", "WriteLatency", "DBClusterIdentifier", local.db_cluster_ids.seoul],
            [".", "ReadLatency", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1" }],
            [".", "WriteLatency", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 18, width = 12, height = 6,
        properties = {
          title  = "Aurora IOPS (Read/Write)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/RDS", "ReadIOPS", "DBClusterIdentifier", local.db_cluster_ids.seoul],
            [".", "WriteIOPS", "DBClusterIdentifier", local.db_cluster_ids.seoul],
            [".", "ReadIOPS", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1" }],
            [".", "WriteIOPS", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 24, width = 12, height = 6,
        properties = {
          title  = "Route53 Health Checks (Seoul/Tokyo)"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", var.route53_healthcheck_ids.seoul],
            [".", "HealthCheckStatus", "HealthCheckId", var.route53_healthcheck_ids.tokyo]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 24, width = 12, height = 6,
        properties = {
          title  = "ALB RequestCount (Seoul/Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_suffixes.seoul],
            [".", "RequestCount", "LoadBalancer", local.alb_suffixes.tokyo, { "region" : "ap-northeast-1" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 30, width = 12, height = 6,
        properties = {
          title  = "ALB 5xx Rate (Seoul)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.seoul, { "id" : "m5xx", "stat" : "Sum", "visible" : false }],
            [".", "RequestCount", ".", ".", { "id" : "req", "stat" : "Sum", "visible" : false }],
            [{ "expression" : "IF(req>0,m5xx/req,0)", "label" : "5xx rate", "id" : "rate" }]
          ]
          period = 60
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type = "metric",
        x    = 12, y = 30, width = 12, height = 6,
        properties = {
          title  = "ALB 5xx Rate (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.tokyo, { "id" : "m5xx", "stat" : "Sum", "region" : "ap-northeast-1", "visible" : false }],
            [".", "RequestCount", ".", ".", { "id" : "req", "stat" : "Sum", "region" : "ap-northeast-1", "visible" : false }],
            [{ "expression" : "IF(req>0,m5xx/req,0)", "label" : "5xx rate", "id" : "rate" }]
          ]
          period = 60
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type = "metric",
        x    = 0, y = 36, width = 12, height = 6,
        properties = {
          title  = "ALB Unhealthy Host Ratio (Seoul)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffix, { "id" : "unh", "stat" : "Average", "visible" : false }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffix, { "id" : "h", "stat" : "Average", "visible" : false }],
            [{ "expression" : "IF((h+unh)>0,unh/(h+unh),0)", "label" : "Unhealthy ratio", "id" : "ratio" }]
          ]
          period = 60
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type = "metric",
        x    = 12, y = 36, width = 12, height = 6,
        properties = {
          title  = "ALB Unhealthy Host Ratio (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", local.alb_suffixes.tokyo, "TargetGroup", local.tg_suffix, { "id" : "unh", "stat" : "Average", "region" : "ap-northeast-1", "visible" : false }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.tokyo, "TargetGroup", local.tg_suffix, { "id" : "h", "stat" : "Average", "region" : "ap-northeast-1", "visible" : false }],
            [{ "expression" : "IF((h+unh)>0,unh/(h+unh),0)", "label" : "Unhealthy ratio", "id" : "ratio" }]
          ]
          period = 60
          yAxis = {
            left = { min = 0 }
          }
        }
      }
    ]
  })
}
