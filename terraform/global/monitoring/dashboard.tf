resource "aws_cloudwatch_dashboard" "ddos_prod" {
  dashboard_name = "DR-Failover-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0, y = 0, width = 12, height = 4,
        properties = {
          title  = "Aurora Writer 리전 (0=서울,1=도쿄)"
          view   = "singleValue"
          region = "ap-northeast-2"
          metrics = [
            [local.metric_namespace, "AuroraWriterRegion", "System", local.metric_dimension_system]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric",
        x    = 12, y = 0, width = 12, height = 4,
        properties = {
          title  = "Route53 활성 리전 (0=서울,1=도쿄)"
          view   = "singleValue"
          region = "ap-northeast-2"
          metrics = [
            [local.metric_namespace, "Route53ActiveRegion", "System", local.metric_dimension_system]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric",
        x    = 0, y = 4, width = 12, height = 6,
        properties = {
          title  = "ALB 요청/5xx (서울)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.seoul_alb_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "TargetResponseTime", ".", ".", { "stat" : "p95" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 4, width = 12, height = 6,
        properties = {
          title  = "ALB 요청/5xx (도쿄)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.tokyo_alb_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "TargetResponseTime", ".", ".", { "stat" : "p95" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 10, width = 12, height = 6,
        properties = {
          title  = "ALB p95 지연 (서울)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.seoul_alb_suffix, { "stat" : "p95" }],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 10, width = 12, height = 6,
        properties = {
          title  = "ALB p95 지연 (도쿄)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.tokyo_alb_suffix, { "stat" : "p95" }],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          period = 60
        }
      }
    ]
  })
}
