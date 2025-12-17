resource "aws_cloudwatch_dashboard" "ddos_prod" {
  dashboard_name = "DR-Failover-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      # ========== 1행: 현재 상태 요약 ==========
      {
        type = "metric",
        x    = 0, y = 0, width = 8, height = 4,
        properties = {
          title  = "현재 DB 쓰기 리전 (0=서울, 1=도쿄)"
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
        x    = 8, y = 0, width = 8, height = 4,
        properties = {
          title  = "현재 트래픽 처리 리전 (0=서울, 1=도쿄)"
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
        type = "text",
        x    = 16, y = 0, width = 8, height = 4,
        properties = {
          markdown = "## 페일오버 체크리스트\n- [ ] 서울 헬스체크 실패 확인\n- [ ] 서울 정상 서버 0대 확인\n- [ ] 도쿄로 트래픽 전환 확인\n- [ ] 도쿄 DB 승격 완료 확인"
        }
      },
      # ========== 2행: 헬스체크 상태 (트래픽 전환 판단) ==========
      {
        type = "metric",
        x    = 0, y = 4, width = 12, height = 5,
        properties = {
          title  = "서울 서버 상태 (1=정상, 0=장애)"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", local.seoul_healthcheck_id, { "label" : "서울 헬스체크", "color" : "#d62728" }]
          ]
          period = 60
          stat   = "Minimum"
          annotations = {
            horizontal = [
              { "label" : "장애 기준", "value" : 0.5, "color" : "#ff0000" }
            ]
          }
        }
      },
      {
        type = "metric",
        x    = 12, y = 4, width = 12, height = 5,
        properties = {
          title  = "도쿄 서버 상태 (1=정상, 0=장애)"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", local.tokyo_healthcheck_id, { "label" : "도쿄 헬스체크", "color" : "#2ca02c" }]
          ]
          period = 60
          stat   = "Minimum"
          annotations = {
            horizontal = [
              { "label" : "장애 기준", "value" : 0.5, "color" : "#ff0000" }
            ]
          }
        }
      },
      # ========== 3행: 정상 서버 수 (인바운드 제거 확인) ==========
      {
        type = "metric",
        x    = 0, y = 9, width = 12, height = 5,
        properties = {
          title  = "서울 정상 서버 수 (0이면 트래픽 차단됨)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.seoul_alb_suffix, "TargetGroup", local.seoul_tg_suffix, { "label" : "정상 서버", "color" : "#2ca02c" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { "label" : "비정상 서버", "color" : "#d62728" }]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type = "metric",
        x    = 12, y = 9, width = 12, height = 5,
        properties = {
          title  = "도쿄 정상 서버 수 (트래픽 수신 가능 확인)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.tokyo_alb_suffix, "TargetGroup", local.tokyo_tg_suffix, { "label" : "정상 서버", "color" : "#2ca02c" }],
            [".", "UnHealthyHostCount", ".", ".", ".", ".", { "label" : "비정상 서버", "color" : "#d62728" }]
          ]
          period = 60
          stat   = "Average"
        }
      },
      # ========== 4행: ASG 인스턴스 수 ==========
      {
        type = "metric",
        x    = 0, y = 14, width = 12, height = 5,
        properties = {
          title  = "서울 실행 중인 서버 수"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", local.seoul_asg_name, { "label" : "실행 중", "color" : "#1f77b4" }],
            [".", "GroupDesiredCapacity", ".", ".", { "label" : "목표 수", "color" : "#ff7f0e" }]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type = "metric",
        x    = 12, y = 14, width = 12, height = 5,
        properties = {
          title  = "도쿄 실행 중인 서버 수"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", local.tokyo_asg_name, { "label" : "실행 중", "color" : "#1f77b4" }],
            [".", "GroupDesiredCapacity", ".", ".", { "label" : "목표 수", "color" : "#ff7f0e" }]
          ]
          period = 60
          stat   = "Average"
        }
      },
      # ========== 5행: DB 연결 및 상태 (쓰기 가능 여부 확인) ==========
      {
        type = "metric",
        x    = 0, y = 19, width = 12, height = 5,
        properties = {
          title  = "서울 DB 연결 수 및 CPU"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", local.seoul_cluster_id, { "label" : "연결 수", "color" : "#1f77b4" }],
            [".", "CPUUtilization", ".", ".", { "label" : "CPU %", "color" : "#ff7f0e", "yAxis" : "right" }]
          ]
          period = 60
          stat   = "Average"
          yAxis = {
            right = { min = 0, max = 100 }
          }
        }
      },
      {
        type = "metric",
        x    = 12, y = 19, width = 12, height = 5,
        properties = {
          title  = "도쿄 DB 연결 수 및 CPU"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", local.tokyo_cluster_id, { "label" : "연결 수", "color" : "#1f77b4" }],
            [".", "CPUUtilization", ".", ".", { "label" : "CPU %", "color" : "#ff7f0e", "yAxis" : "right" }]
          ]
          period = 60
          stat   = "Average"
          yAxis = {
            right = { min = 0, max = 100 }
          }
        }
      },
      # ========== 6행: 트래픽 및 오류 (페일오버 후 정상 동작 확인) ==========
      {
        type = "metric",
        x    = 0, y = 24, width = 12, height = 5,
        properties = {
          title  = "서울 요청 수 및 오류 (페일오버 후 0이어야 함)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.seoul_alb_suffix, { "label" : "요청 수", "color" : "#1f77b4" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { "label" : "서버 오류(5xx)", "color" : "#d62728" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type = "metric",
        x    = 12, y = 24, width = 12, height = 5,
        properties = {
          title  = "도쿄 요청 수 및 오류 (트래픽 수신 확인)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.tokyo_alb_suffix, { "label" : "요청 수", "color" : "#1f77b4" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { "label" : "서버 오류(5xx)", "color" : "#d62728" }]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      # ========== 7행: 응답 시간 ==========
      {
        type = "metric",
        x    = 0, y = 29, width = 12, height = 5,
        properties = {
          title  = "서울 응답 시간 (95% 기준)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.seoul_alb_suffix, { "stat" : "p95", "label" : "응답시간 p95", "color" : "#9467bd" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 29, width = 12, height = 5,
        properties = {
          title  = "도쿄 응답 시간 (95% 기준)"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.tokyo_alb_suffix, { "stat" : "p95", "label" : "응답시간 p95", "color" : "#9467bd" }]
          ]
          period = 60
        }
      }
    ]
  })
}
