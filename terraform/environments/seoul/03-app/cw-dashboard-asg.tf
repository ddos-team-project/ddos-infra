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
          title  = "ASG 인스턴스 수 (서울)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name, { "color" : "#2ca02c", "label" : "목표" }],
            [".", "GroupInServiceInstances", ".", ".", { "color" : "#1f77b4", "label" : "실행중" }],
            [".", "GroupPendingInstances", ".", ".", { "color" : "#ff7f0e", "label" : "대기중" }],
            [".", "GroupTerminatingInstances", ".", ".", { "color" : "#d62728", "label" : "종료중" }]
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
          title  = "ASG 인스턴스 수 (도쿄)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", "healthcheck-api-tokyo-asg", { "color" : "#2ca02c", "label" : "목표", "region" : "ap-northeast-1" }],
            [".", "GroupInServiceInstances", ".", ".", { "color" : "#1f77b4", "label" : "실행중", "region" : "ap-northeast-1" }],
            [".", "GroupPendingInstances", ".", ".", { "color" : "#ff7f0e", "label" : "대기중", "region" : "ap-northeast-1" }],
            [".", "GroupTerminatingInstances", ".", ".", { "color" : "#d62728", "label" : "종료중", "region" : "ap-northeast-1" }]
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
          title  = "CPU 사용률 (서울)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name, { "stat" : "Average", "label" : "평균" }],
            ["...", { "stat" : "Maximum", "label" : "최대", "color" : "#d62728" }]
          ]
          period = 60
          annotations = {
            horizontal = [
              { "label" : "스케일 아웃 임계값", "value" : 70, "color" : "#ff7f0e" }
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
          title  = "CPU 사용률 (도쿄)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "healthcheck-api-tokyo-asg", { "stat" : "Average", "label" : "평균", "region" : "ap-northeast-1" }],
            ["...", { "stat" : "Maximum", "label" : "최대", "color" : "#d62728", "region" : "ap-northeast-1" }]
          ]
          period = 60
          annotations = {
            horizontal = [
              { "label" : "스케일 아웃 임계값", "value" : 70, "color" : "#ff7f0e" }
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
          title  = "ALB 요청 수 (서울/도쿄)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_suffixes.seoul, { "stat" : "Sum", "label" : "서울" }],
            [".", "RequestCount", "LoadBalancer", local.alb_suffixes.tokyo, { "stat" : "Sum", "label" : "도쿄", "region" : "ap-northeast-1" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 12, width = 12, height = 6,
        properties = {
          title  = "응답 시간 P50/P95/P99 (서울)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.seoul, { "stat" : "p50", "label" : "P50" }],
            ["...", { "stat" : "p95", "label" : "P95", "color" : "#ff7f0e" }],
            ["...", { "stat" : "p99", "label" : "P99", "color" : "#d62728" }]
          ]
          period = 60
        }
      },
      # Row 4: Target Group Health & Connection
      {
        type = "metric",
        x    = 0, y = 18, width = 12, height = 6,
        properties = {
          title  = "타겟 그룹 상태 (서울)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffix, { "color" : "#2ca02c", "label" : "정상" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { "color" : "#d62728", "label" : "비정상" }]
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
          title  = "ALB 연결 수 (서울)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", local.alb_suffixes.seoul, { "label" : "활성" }],
            [".", "NewConnectionCount", ".", ".", { "label" : "신규", "color" : "#ff7f0e" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      # Row 5: HTTP Status Codes
      {
        type = "metric",
        x    = 0, y = 24, width = 12, height = 6,
        properties = {
          title  = "HTTP 상태 코드 (서울)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", local.alb_suffixes.seoul, { "color" : "#2ca02c", "label" : "2XX 성공" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { "color" : "#ff7f0e", "label" : "4XX 클라이언트 에러" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { "color" : "#d62728", "label" : "5XX 서버 에러" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type = "metric",
        x    = 12, y = 24, width = 12, height = 6,
        properties = {
          title  = "HTTP 상태 코드 (도쿄)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", local.alb_suffixes.tokyo, { "color" : "#2ca02c", "label" : "2XX 성공", "region" : "ap-northeast-1" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { "color" : "#ff7f0e", "label" : "4XX 클라이언트 에러", "region" : "ap-northeast-1" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { "color" : "#d62728", "label" : "5XX 서버 에러", "region" : "ap-northeast-1" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      # Row 6: Network Traffic
      {
        type = "metric",
        x    = 0, y = 30, width = 12, height = 6,
        properties = {
          title  = "네트워크 트래픽 (서울)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name, { "label" : "수신 (bytes)" }],
            [".", "NetworkOut", ".", ".", { "label" : "송신 (bytes)", "color" : "#ff7f0e" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type = "metric",
        x    = 12, y = 30, width = 12, height = 6,
        properties = {
          title  = "네트워크 트래픽 (도쿄)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", "healthcheck-api-tokyo-asg", { "label" : "수신 (bytes)", "region" : "ap-northeast-1" }],
            [".", "NetworkOut", ".", ".", { "label" : "송신 (bytes)", "color" : "#ff7f0e", "region" : "ap-northeast-1" }]
          ]
          period = 60
          stat   = "Sum"
        }
      }
    ]
  })
}
