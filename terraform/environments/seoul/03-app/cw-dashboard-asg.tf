# ASG 부하 테스트 대시보드
resource "aws_cloudwatch_dashboard" "asg_load_test" {
  dashboard_name = "ASG-Load-Test"
  dashboard_body = jsonencode({
    widgets = [
      # Row 1: ASG 인스턴스 수 (서울/도쿄)
      {
        type = "metric",
        x    = 0, y = 0, width = 12, height = 6,
        properties = {
          title  = "ASG Instance Count (Seoul)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name, { "color" : "#2ca02c", "label" : "Desired" }],
            [".", "GroupInServiceInstances", ".", ".", { "color" : "#1f77b4", "label" : "InService" }],
            [".", "GroupPendingInstances", ".", ".", { "color" : "#ff7f0e", "label" : "Pending" }],
            [".", "GroupTerminatingInstances", ".", ".", { "color" : "#d62728", "label" : "Terminating" }]
          ]
          period = 60
          stat   = "Average"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type = "metric",
        x    = 12, y = 0, width = 12, height = 6,
        properties = {
          title  = "ASG Instance Count (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", local.tokyo_asg_name, { "color" : "#2ca02c", "label" : "Desired", "region" : "ap-northeast-1" }],
            [".", "GroupInServiceInstances", ".", ".", { "color" : "#1f77b4", "label" : "InService", "region" : "ap-northeast-1" }],
            [".", "GroupPendingInstances", ".", ".", { "color" : "#ff7f0e", "label" : "Pending", "region" : "ap-northeast-1" }],
            [".", "GroupTerminatingInstances", ".", ".", { "color" : "#d62728", "label" : "Terminating", "region" : "ap-northeast-1" }]
          ]
          period = 60
          stat   = "Average"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      # Row 2: CPU 사용률 (스케일링 트리거 기준)
      {
        type = "metric",
        x    = 0, y = 6, width = 12, height = 6,
        properties = {
          title  = "ASG CPU Utilization (Seoul)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name, { "stat" : "Average", "label" : "Avg CPU" }],
            ["...", { "stat" : "Maximum", "label" : "Max CPU", "color" : "#d62728" }]
          ]
          period = 60
          annotations = {
            horizontal = [
              { "label" : "Scale Out Threshold", "value" : 70, "color" : "#ff7f0e" }
            ]
          }
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      {
        type = "metric",
        x    = 12, y = 6, width = 12, height = 6,
        properties = {
          title  = "ASG CPU Utilization (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", local.tokyo_asg_name, { "stat" : "Average", "label" : "Avg CPU", "region" : "ap-northeast-1" }],
            ["...", { "stat" : "Maximum", "label" : "Max CPU", "color" : "#d62728", "region" : "ap-northeast-1" }]
          ]
          period = 60
          annotations = {
            horizontal = [
              { "label" : "Scale Out Threshold", "value" : 70, "color" : "#ff7f0e" }
            ]
          }
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      # Row 3: ALB Request Count & Response Time
      {
        type = "metric",
        x    = 0, y = 12, width = 12, height = 6,
        properties = {
          title  = "ALB Request Count (Seoul/Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_suffixes.seoul, { "stat" : "Sum", "label" : "Seoul RPS" }],
            [".", "RequestCount", "LoadBalancer", local.alb_suffixes.tokyo, { "stat" : "Sum", "label" : "Tokyo RPS", "region" : "ap-northeast-1" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 12, width = 12, height = 6,
        properties = {
          title  = "ALB Response Time P50/P95/P99 (Seoul/Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.seoul, { "stat" : "p50", "label" : "Seoul P50" }],
            ["...", { "stat" : "p95", "label" : "Seoul P95", "color" : "#ff7f0e" }],
            ["...", { "stat" : "p99", "label" : "Seoul P99", "color" : "#d62728" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.tokyo, { "stat" : "p50", "label" : "Tokyo P50", "region" : "ap-northeast-1", "color" : "#17becf" }],
            ["...", { "stat" : "p95", "label" : "Tokyo P95", "region" : "ap-northeast-1", "color" : "#bcbd22" }],
            ["...", { "stat" : "p99", "label" : "Tokyo P99", "region" : "ap-northeast-1", "color" : "#e377c2" }]
          ]
          period = 60
        }
      },
      # Row 4: Target Group Health & Connection
      {
        type = "metric",
        x    = 0, y = 18, width = 12, height = 6,
        properties = {
          title  = "Target Group Health (Seoul)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffixes.seoul, { "color" : "#2ca02c", "label" : "Healthy" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { "color" : "#d62728", "label" : "Unhealthy" }]
          ]
          period = 60
          stat   = "Average"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      {
        type = "metric",
        x    = 12, y = 18, width = 12, height = 6,
        properties = {
          title  = "Target Group Health (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.tokyo, "TargetGroup", local.tg_suffixes.tokyo, { "color" : "#2ca02c", "label" : "Healthy", "region" : "ap-northeast-1" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { "color" : "#d62728", "label" : "Unhealthy", "region" : "ap-northeast-1" }]
          ]
          period = 60
          stat   = "Average"
          yAxis = {
            left = { min = 0 }
          }
        }
      },
      # Row 5: ALB Connections
      {
        type = "metric",
        x    = 0, y = 24, width = 12, height = 6,
        properties = {
          title  = "ALB Connections (Seoul)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", local.alb_suffixes.seoul, { "label" : "Active" }],
            [".", "NewConnectionCount", ".", ".", { "label" : "New", "color" : "#ff7f0e" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type = "metric",
        x    = 12, y = 24, width = 12, height = 6,
        properties = {
          title  = "ALB Connections (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", local.alb_suffixes.tokyo, { "label" : "Active", "region" : "ap-northeast-1" }],
            [".", "NewConnectionCount", ".", ".", { "label" : "New", "color" : "#ff7f0e", "region" : "ap-northeast-1" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      # Row 6: HTTP Status Codes
      {
        type = "metric",
        x    = 0, y = 30, width = 12, height = 6,
        properties = {
          title  = "HTTP Status Codes (Seoul)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", local.alb_suffixes.seoul, { "color" : "#2ca02c", "label" : "2XX" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { "color" : "#ff7f0e", "label" : "4XX" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { "color" : "#d62728", "label" : "5XX" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type = "metric",
        x    = 12, y = 30, width = 12, height = 6,
        properties = {
          title  = "HTTP Status Codes (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", local.alb_suffixes.tokyo, { "color" : "#2ca02c", "label" : "2XX", "region" : "ap-northeast-1" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { "color" : "#ff7f0e", "label" : "4XX", "region" : "ap-northeast-1" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { "color" : "#d62728", "label" : "5XX", "region" : "ap-northeast-1" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      # Row 7: Network Traffic
      {
        type = "metric",
        x    = 0, y = 36, width = 12, height = 6,
        properties = {
          title  = "Network Traffic (Seoul ASG)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name, { "label" : "Network In (bytes)" }],
            [".", "NetworkOut", ".", ".", { "label" : "Network Out (bytes)", "color" : "#ff7f0e" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type = "metric",
        x    = 12, y = 36, width = 12, height = 6,
        properties = {
          title  = "Network Traffic (Tokyo ASG)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", local.tokyo_asg_name, { "label" : "Network In (bytes)", "region" : "ap-northeast-1" }],
            [".", "NetworkOut", ".", ".", { "label" : "Network Out (bytes)", "color" : "#ff7f0e", "region" : "ap-northeast-1" }]
          ]
          period = 60
          stat   = "Sum"
        }
      }
    ]
  })
}
