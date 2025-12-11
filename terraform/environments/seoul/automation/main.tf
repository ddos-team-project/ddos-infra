# Data sources for current AWS account and region
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# 1. SSM Automation을 실행할 IAM 역할 생성 (Failover/Failback 공용)
resource "aws_iam_role" "ssm_automation_failover_role" {
  name = "SSMAutomation-AuroraRole-Seoul" # Failover와 Failback 모두 사용

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ssm.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# 2. 역할에 부여할 권한 정책(Policy) 정의
resource "aws_iam_policy" "ssm_automation_failover_policy" {
  name        = "SSMAutomation-AuroraPolicy-Seoul" # Failover와 Failback 모두 사용
  description = "Policy for Aurora Global DB Failover and Failback Automation in Seoul environment"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      # RDS Global Cluster를 다룰 권한
      {
        Effect   = "Allow",
        Action   = [
          "rds:FailoverGlobalCluster",
          "rds:DescribeGlobalClusters",
          "rds:DescribeDBClusters"
        ],
        Resource = "*" # 실제 환경에서는 특정 클러스터 ARN으로 제한하는 것이 더 안전함
      },
      # SSM Parameter를 수정할 권한
      {
        Effect   = "Allow",
        Action   = "ssm:PutParameter",
        # 특정 파라미터에만 접근하도록 ARN을 명시하여 권한 최소화
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.db_endpoint_parameter_name}"
      }
    ]
  })
}

# 3. 위에서 만든 역할(Role)과 정책(Policy)을 연결
resource "aws_iam_role_policy_attachment" "ssm_automation_failover_attach" {
  role       = aws_iam_role.ssm_automation_failover_role.name
  policy_arn = aws_iam_policy.ssm_automation_failover_policy.arn
}

# 4. SSM Automation Document 정의 - Failover
resource "aws_ssm_document" "aurora_failover_runbook" {
  name            = "Aurora-Failover-Runbook-Seoul" # 환경에 따라 이름을 명확히
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-failover-runbook.yml")

  tags = local.common_tags
}

# 5. SSM Automation Document 정의 - Failback
resource "aws_ssm_document" "aurora_failback_runbook" {
  name            = "Aurora-Failback-Runbook-Seoul" # 환경에 따라 이름을 명확히
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-failback-runbook.yml")

  tags = local.common_tags
}
