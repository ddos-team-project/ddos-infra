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
          "rds:RemoveFromGlobalCluster",
          "rds:CreateGlobalCluster",
          "rds:DescribeGlobalClusters",
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusterSnapshots",
          "rds:ModifyDBCluster",
          "rds:CreateDBClusterSnapshot",
          "rds:CreateDBInstance",
          "rds:RestoreDBClusterFromSnapshot"
        ],
        Resource = "*"
      },
      # SSM Parameter 권한
      {
        Effect   = "Allow",
        Action   = ["ssm:PutParameter", "ssm:GetParameter"],
        Resource = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/ddos/aurora/*"
      },
      # CloudWatch 권한
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:GetMetricStatistics"
        ],
        Resource = "*"
      },
      # EC2 권한 (VPC/Subnet 확인)
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets"
        ],
        Resource = "*"
      },
      # KMS 권한
      {
        Effect = "Allow",
        Action = [
          "kms:ListKeys",
          "kms:DescribeKey"
        ],
        Resource = "*"
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

# SSM Automation Document - Disaster Failover (리전 전체 장애 시)
resource "aws_ssm_document" "aurora_disaster_failover_runbook" {
  name            = "Aurora-Disaster-Failover-Runbook-${var.region_name}"
  document_type   = "Automation"
  document_format = "YAML"

  content = var.disaster_failover_runbook_content

  tags = var.tags
}

# ===== Seoul Disaster Recovery Failback Runbooks =====

# SSM Automation Document - Disaster Recovery Step 1: Verify (Seoul)
resource "aws_ssm_document" "disaster_recovery_verify" {
  count           = var.disaster_recovery_verify_content != "" ? 1 : 0
  name            = "Aurora-Disaster-Recovery-1-Verify-${var.region_name}"
  document_type   = "Automation"
  document_format = "YAML"

  content = var.disaster_recovery_verify_content

  tags = var.tags
}

# SSM Automation Document - Disaster Recovery Step 2: Create Cluster (Seoul)
resource "aws_ssm_document" "disaster_recovery_create_cluster" {
  count           = var.disaster_recovery_create_cluster_content != "" ? 1 : 0
  name            = "Aurora-Disaster-Recovery-2-CreateCluster-${var.region_name}"
  document_type   = "Automation"
  document_format = "YAML"

  content = var.disaster_recovery_create_cluster_content

  tags = var.tags
}

# SSM Automation Document - Disaster Recovery Step 3: Add Secondary (Seoul)
resource "aws_ssm_document" "disaster_recovery_add_secondary" {
  count           = var.disaster_recovery_add_secondary_content != "" ? 1 : 0
  name            = "Aurora-Disaster-Recovery-3-AddSecondary-${var.region_name}"
  document_type   = "Automation"
  document_format = "YAML"

  content = var.disaster_recovery_add_secondary_content

  tags = var.tags
}

# SSM Automation Document - Disaster Recovery Step 4: Verify Replication (Seoul)
resource "aws_ssm_document" "disaster_recovery_verify_replication" {
  count           = var.disaster_recovery_verify_replication_content != "" ? 1 : 0
  name            = "Aurora-Disaster-Recovery-4-VerifyReplication-${var.region_name}"
  document_type   = "Automation"
  document_format = "YAML"

  content = var.disaster_recovery_verify_replication_content

  tags = var.tags
}

# ===== Tokyo Disaster Recovery Failback Runbooks =====

# SSM Automation Document - Disaster Recovery Prepare Failback (Tokyo)
resource "aws_ssm_document" "disaster_recovery_prepare_failback" {
  count           = var.disaster_recovery_prepare_failback_content != "" ? 1 : 0
  name            = "Aurora-Disaster-Recovery-Prepare-Failback-${var.region_name}"
  document_type   = "Automation"
  document_format = "YAML"

  content = var.disaster_recovery_prepare_failback_content

  tags = var.tags
}

# SSM Automation Document - Disaster Recovery Recreate Global (Tokyo)
resource "aws_ssm_document" "disaster_recovery_recreate_global" {
  count           = var.disaster_recovery_recreate_global_content != "" ? 1 : 0
  name            = "Aurora-Disaster-Recovery-Recreate-Global-${var.region_name}"
  document_type   = "Automation"
  document_format = "YAML"

  content = var.disaster_recovery_recreate_global_content

  tags = var.tags
}
