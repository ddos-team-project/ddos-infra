resource "aws_cloudwatch_dashboard" "dr_failover_summary" {
  provider       = aws.global
  dashboard_name = "DR-Failover-Dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0, y = 0, width = 24, height = 6,
        properties = {
          title  = "서비스 상태 (1=정상, 0=장애)"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", var.route53_healthcheck_ids.seoul, { "label" : "서울" }],
            [".", "HealthCheckStatus", "HealthCheckId", var.route53_healthcheck_ids.tokyo, { "label" : "도쿄" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 6, width = 12, height = 6,
        properties = {
          title  = "서울 오류율 (%) - 낮을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.seoul, { "id" : "m5xx", "stat" : "Sum", "visible" : false }],
            [".", "RequestCount", ".", ".", { "id" : "req", "stat" : "Sum", "visible" : false }],
            [{ "expression" : "IF(req>0,(m5xx/req)*100,0)", "label" : "오류율 (%)", "id" : "rate" }]
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
          title  = "도쿄 오류율 (%) - 낮을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.tokyo, { "id" : "m5xx", "stat" : "Sum", "region" : "ap-northeast-1", "visible" : false }],
            [".", "RequestCount", ".", ".", { "id" : "req", "stat" : "Sum", "region" : "ap-northeast-1", "visible" : false }],
            [{ "expression" : "IF(req>0,(m5xx/req)*100,0)", "label" : "오류율 (%)", "id" : "rate" }]
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
          title  = "서울 서버 정상 비율 (%) - 높을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffix, { "id" : "unh", "stat" : "Average", "visible" : false }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffix, { "id" : "h", "stat" : "Average", "visible" : false }],
            [{ "expression" : "IF((h+unh)>0,(h/(h+unh))*100,0)", "label" : "정상 비율 (%)", "id" : "ratio" }]
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
          title  = "도쿄 서버 정상 비율 (%) - 높을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", local.alb_suffixes.tokyo, "TargetGroup", local.tg_suffixes.tokyo, { "id" : "unh", "stat" : "Average", "region" : "ap-northeast-1", "visible" : false }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.tokyo, "TargetGroup", local.tg_suffixes.tokyo, { "id" : "h", "stat" : "Average", "region" : "ap-northeast-1", "visible" : false }],
            [{ "expression" : "IF((h+unh)>0,(h/(h+unh))*100,0)", "label" : "정상 비율 (%)", "id" : "ratio" }]
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
          title  = "응답 시간 (초) - 낮을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.seoul, { "stat" : "p95", "label" : "서울 (상위 5%)" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.tokyo, { "region" : "ap-northeast-1", "stat" : "p95", "label" : "도쿄 (상위 5%)" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 24, width = 24, height = 4,
        properties = {
          title  = "분당 요청 수"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_suffixes.seoul, { "label" : "서울" }],
            [".", "RequestCount", "LoadBalancer", local.alb_suffixes.tokyo, { "region" : "ap-northeast-1", "label" : "도쿄" }]
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
          title  = "서울 - 서버 오류 및 응답 지연"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.seoul, { "label" : "서버 오류 수 (5xx)" }],
            [".", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.seoul, { "stat" : "p95", "label" : "응답 시간 (초)" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 0, width = 12, height = 6,
        properties = {
          title  = "서울 - 서버 CPU 및 상태"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name, { "label" : "CPU 사용률 (%)" }],
            ["AWS/EC2", "StatusCheckFailed", "AutoScalingGroupName", module.healthcheck_api_asg.autoscaling_group_name, { "label" : "상태 점검 실패 (0=정상)" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 6, width = 12, height = 6,
        properties = {
          title  = "도쿄 - 서버 오류 및 응답 지연"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.tokyo, { "region" : "ap-northeast-1", "label" : "서버 오류 수 (5xx)" }],
            [".", "TargetResponseTime", "LoadBalancer", local.alb_suffixes.tokyo, { "region" : "ap-northeast-1", "stat" : "p95", "label" : "응답 시간 (초)" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 6, width = 12, height = 6,
        properties = {
          title  = "도쿄 - 서버 CPU 및 상태"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "healthcheck-api-tokyo-asg", { "label" : "CPU 사용률 (%)" }],
            ["AWS/EC2", "StatusCheckFailed", "AutoScalingGroupName", "healthcheck-api-tokyo-asg", { "label" : "상태 점검 실패 (0=정상)" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 12, width = 12, height = 6,
        properties = {
          title  = "DB 복제 지연 (밀리초) - 낮을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/RDS", "AuroraGlobalDBReplicationLag", "DBClusterIdentifier", local.db_cluster_ids.seoul, { "label" : "서울" }],
            [".", "AuroraGlobalDBReplicationLag", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1", "label" : "도쿄" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 12, width = 12, height = 6,
        properties = {
          title  = "DB 연결 수 및 여유 메모리"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", local.db_cluster_ids.seoul, { "label" : "서울 연결 수" }],
            [".", "FreeableMemory", "DBClusterIdentifier", local.db_cluster_ids.seoul, { "label" : "서울 여유 메모리" }],
            [".", "DatabaseConnections", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1", "label" : "도쿄 연결 수" }],
            [".", "FreeableMemory", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1", "label" : "도쿄 여유 메모리" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 18, width = 12, height = 6,
        properties = {
          title  = "DB 응답 시간 (초) - 낮을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/RDS", "ReadLatency", "DBClusterIdentifier", local.db_cluster_ids.seoul, { "label" : "서울 읽기" }],
            [".", "WriteLatency", "DBClusterIdentifier", local.db_cluster_ids.seoul, { "label" : "서울 쓰기" }],
            [".", "ReadLatency", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1", "label" : "도쿄 읽기" }],
            [".", "WriteLatency", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1", "label" : "도쿄 쓰기" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 18, width = 12, height = 6,
        properties = {
          title  = "DB 입출력 횟수 (IOPS)"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/RDS", "ReadIOPS", "DBClusterIdentifier", local.db_cluster_ids.seoul, { "label" : "서울 읽기" }],
            [".", "WriteIOPS", "DBClusterIdentifier", local.db_cluster_ids.seoul, { "label" : "서울 쓰기" }],
            [".", "ReadIOPS", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1", "label" : "도쿄 읽기" }],
            [".", "WriteIOPS", "DBClusterIdentifier", local.db_cluster_ids.tokyo, { "region" : "ap-northeast-1", "label" : "도쿄 쓰기" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 24, width = 12, height = 6,
        properties = {
          title  = "헬스체크 상태 (1=정상, 0=장애)"
          view   = "timeSeries"
          region = "us-east-1"
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", var.route53_healthcheck_ids.seoul, { "label" : "서울" }],
            [".", "HealthCheckStatus", "HealthCheckId", var.route53_healthcheck_ids.tokyo, { "label" : "도쿄" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 12, y = 24, width = 12, height = 6,
        properties = {
          title  = "분당 요청 수"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.alb_suffixes.seoul, { "label" : "서울" }],
            [".", "RequestCount", "LoadBalancer", local.alb_suffixes.tokyo, { "region" : "ap-northeast-1", "label" : "도쿄" }]
          ]
          period = 60
        }
      },
      {
        type = "metric",
        x    = 0, y = 30, width = 12, height = 6,
        properties = {
          title  = "서울 오류 비율 - 낮을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.seoul, { "id" : "m5xx", "stat" : "Sum", "visible" : false }],
            [".", "RequestCount", ".", ".", { "id" : "req", "stat" : "Sum", "visible" : false }],
            [{ "expression" : "IF(req>0,m5xx/req,0)", "label" : "오류 비율", "id" : "rate" }]
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
          title  = "도쿄 오류 비율 - 낮을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", local.alb_suffixes.tokyo, { "id" : "m5xx", "stat" : "Sum", "region" : "ap-northeast-1", "visible" : false }],
            [".", "RequestCount", ".", ".", { "id" : "req", "stat" : "Sum", "region" : "ap-northeast-1", "visible" : false }],
            [{ "expression" : "IF(req>0,m5xx/req,0)", "label" : "오류 비율", "id" : "rate" }]
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
          title  = "서울 비정상 서버 비율 - 낮을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-2"
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffix, { "id" : "unh", "stat" : "Average", "visible" : false }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.seoul, "TargetGroup", local.tg_suffix, { "id" : "h", "stat" : "Average", "visible" : false }],
            [{ "expression" : "IF((h+unh)>0,unh/(h+unh),0)", "label" : "비정상 비율", "id" : "ratio" }]
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
          title  = "도쿄 비정상 서버 비율 - 낮을수록 좋음"
          view   = "timeSeries"
          region = "ap-northeast-1"
          metrics = [
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", local.alb_suffixes.tokyo, "TargetGroup", local.tg_suffixes.tokyo, { "id" : "unh", "stat" : "Average", "region" : "ap-northeast-1", "visible" : false }],
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_suffixes.tokyo, "TargetGroup", local.tg_suffixes.tokyo, { "id" : "h", "stat" : "Average", "region" : "ap-northeast-1", "visible" : false }],
            [{ "expression" : "IF((h+unh)>0,unh/(h+unh),0)", "label" : "비정상 비율", "id" : "ratio" }]
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
