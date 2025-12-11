# Data sources for current AWS account and region
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# SSM Automation을 실행할 IAM 역할 생성
resource "aws_iam_role" "ssm_automation_role" {
  name = "SSMAutomation-AuroraRole-${var.region_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ssm.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM 권한 정책 정의
resource "aws_iam_policy" "ssm_automation_policy" {
  name        = "SSMAutomation-AuroraPolicy-${var.region_name}"
  description = "Policy for Aurora Global DB Failover and Failback Automation in ${var.region_name}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # RDS Global Cluster 권한
      {
        Effect = "Allow",
        Action = [
          "rds:FailoverGlobalCluster",
          "rds:DescribeGlobalClusters",
          "rds:DescribeDBClusters"
        ],
        Resource = "*"
      },
      # SSM Parameter 수정 권한
      {
        Effect   = "Allow",
        Action   = "ssm:PutParameter",
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.db_endpoint_parameter_name}"
      }
    ]
  })

  tags = var.tags
}

# IAM Role과 Policy 연결
resource "aws_iam_role_policy_attachment" "ssm_automation_attach" {
  role       = aws_iam_role.ssm_automation_role.name
  policy_arn = aws_iam_policy.ssm_automation_policy.arn
}

# SSM Automation Document - Failover
resource "aws_ssm_document" "aurora_failover_runbook" {
  name            = "Aurora-Failover-Runbook-${var.region_name}"
  document_type   = "Automation"
  document_format = "YAML"

  content = var.failover_runbook_content

  tags = var.tags
}

# SSM Automation Document - Failback
resource "aws_ssm_document" "aurora_failback_runbook" {
  name            = "Aurora-Failback-Runbook-${var.region_name}"
  document_type   = "Automation"
  document_format = "YAML"

  content = var.failback_runbook_content

  tags = var.tags
}
