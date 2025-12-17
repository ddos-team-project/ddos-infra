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
          title  = "서울 서버 수"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name, { "color" : "#2ca02c", "label" : "목표 수" }],
            [".", "GroupInServiceInstances", ".", ".", { "color" : "#1f77b4", "label" : "가동 중" }],
            [".", "GroupPendingInstances", ".", ".", { "color" : "#ff7f0e", "label" : "시작 중" }],
            [".", "GroupTerminatingInstances", ".", ".", { "color" : "#d62728", "label" : "종료 중" }]
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
          title  = "도쿄 서버 수"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", local.tokyo_asg_name, { "color" : "#2ca02c", "label" : "목표 수", "region" : "ap-northeast-1" }],
            [".", "GroupInServiceInstances", ".", ".", { "color" : "#1f77b4", "label" : "가동 중", "region" : "ap-northeast-1" }],
            [".", "GroupPendingInstances", ".", ".", { "color" : "#ff7f0e", "label" : "시작 중", "region" : "ap-northeast-1" }],
            [".", "GroupTerminatingInstances", ".", ".", { "color" : "#d62728", "label" : "종료 중", "region" : "ap-northeast-1" }]
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
          title  = "서울 CPU 사용률 (%) - 70% 초과시 서버 추가"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name, { "stat" : "Average", "label" : "평균" }],
            ["...", { "stat" : "Maximum", "label" : "최대", "color" : "#d62728" }]
          ]
          period = 60
          annotations = {
            horizontal = [
              { "label" : "서버 추가 기준선", "value" : 70, "color" : "#ff7f0e" }
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
          title  = "도쿄 CPU 사용률 (%) - 70% 초과시 서버 추가"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", local.tokyo_asg_name, { "stat" : "Average", "label" : "평균", "region" : "ap-northeast-1" }],
            ["...", { "stat" : "Maximum", "label" : "최대", "color" : "#d62728", "region" : "ap-northeast-1" }]
          ]
          period = 60
          annotations = {
            horizontal = [
              { "label" : "서버 추가 기준선", "value" : 70, "color" : "#ff7f0e" }
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
          title  = "분당 요청 수"
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
          title  = "응답 시간 (초) - 낮을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.seoul, { "stat" : "p50", "label" : "서울 중간값" }],
            ["...", { "stat" : "p95", "label" : "서울 상위5%", "color" : "#ff7f0e" }],
            ["...", { "stat" : "p99", "label" : "서울 상위1%", "color" : "#d62728" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.tokyo, { "stat" : "p50", "label" : "도쿄 중간값", "region" : "ap-northeast-1", "color" : "#17becf" }],
            ["...", { "stat" : "p95", "label" : "도쿄 상위5%", "region" : "ap-northeast-1", "color" : "#bcbd22" }],
            ["...", { "stat" : "p99", "label" : "도쿄 상위1%", "region" : "ap-northeast-1", "color" : "#e377c2" }]
          ]
          period = 60
        }
      },
      # Row 4: Target Group Health
      {
        type = "metric",
        x    = 0, y = 18, width = 12, height = 6,
        properties = {
          title  = "서울 서버 상태"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffixes.seoul, { "color" : "#2ca02c", "label" : "정상" }],
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
          title  = "도쿄 서버 상태"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.tokyo, "TargetGroup", local.tg_suffixes.tokyo, { "color" : "#2ca02c", "label" : "정상", "region" : "ap-northeast-1" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { "color" : "#d62728", "label" : "비정상", "region" : "ap-northeast-1" }]
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
          title  = "서울 연결 수"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", local.alb_suffixes.seoul, { "label" : "현재 연결" }],
            [".", "NewConnectionCount", ".", ".", { "label" : "신규 연결", "color" : "#ff7f0e" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type = "metric",
        x    = 12, y = 24, width = 12, height = 6,
        properties = {
          title  = "도쿄 연결 수"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", local.alb_suffixes.tokyo, { "label" : "현재 연결", "region" : "ap-northeast-1" }],
            [".", "NewConnectionCount", ".", ".", { "label" : "신규 연결", "color" : "#ff7f0e", "region" : "ap-northeast-1" }]
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
          title  = "서울 응답 코드 (2XX=성공, 4XX=요청오류, 5XX=서버오류)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", local.alb_suffixes.seoul, { "color" : "#2ca02c", "label" : "성공 (2XX)" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { "color" : "#ff7f0e", "label" : "요청오류 (4XX)" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { "color" : "#d62728", "label" : "서버오류 (5XX)" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type = "metric",
        x    = 12, y = 30, width = 12, height = 6,
        properties = {
          title  = "도쿄 응답 코드 (2XX=성공, 4XX=요청오류, 5XX=서버오류)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", local.alb_suffixes.tokyo, { "color" : "#2ca02c", "label" : "성공 (2XX)", "region" : "ap-northeast-1" }],
            [".", "HTTPCode_Target_4XX_Count", ".", ".", { "color" : "#ff7f0e", "label" : "요청오류 (4XX)", "region" : "ap-northeast-1" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { "color" : "#d62728", "label" : "서버오류 (5XX)", "region" : "ap-northeast-1" }]
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
          title  = "서울 네트워크 트래픽"
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
        x    = 12, y = 36, width = 12, height = 6,
        properties = {
          title  = "도쿄 네트워크 트래픽"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/EC2", "NetworkIn", "AutoScalingGroupName", local.tokyo_asg_name, { "label" : "수신 (bytes)", "region" : "ap-northeast-1" }],
            [".", "NetworkOut", ".", ".", { "label" : "송신 (bytes)", "color" : "#ff7f0e", "region" : "ap-northeast-1" }]
          ]
          period = 60
          stat   = "Sum"
        }
      }
    ]
  })
}
