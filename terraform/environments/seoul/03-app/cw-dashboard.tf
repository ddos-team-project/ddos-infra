resource "aws_cloudwatch_dashboard" "ddos_prod" {
  dashboard_name = "DDOS-Production"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0, y = 0, width = 12, height = 6,
        properties = {
          title  = "ALB Req & 5XX (Seoul)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_suffix],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "TargetResponseTime", ".", ".", { "stat" : "p95" }]
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
          title  = "ALB Req & 5XX (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/healthcheck-api-tokyo-alb/e96ebc5e91cc7975"],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "TargetResponseTime", ".", ".", { "stat" : "p95" }]
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
        x    = 0, y = 6, width = 12, height = 6,
        properties = {
          title  = "ALB Req & 5XX (Tokyo)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/healthcheck-api-tokyo-alb/e96ebc5e91cc7975"],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "TargetResponseTime", ".", ".", { "stat" : "p95" }]
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
      }

    ]
  })
}
