# IAM Role 생성 (공통 모듈)
module "aurora_automation" {
  source = "../../../modules/aurora-automation"

  region_name = "Tokyo"
  environment = var.environment

  tags = local.common_tags
}

# SSM Automation Document - Failover (Seoul 장애 시 Tokyo 독립 운영)
resource "aws_ssm_document" "aurora_failover_runbook" {
  name            = "Aurora-Failover-Runbook-Tokyo"
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-failover-runbook.yml")

  tags = local.common_tags
}

# SSM Automation Document - Failback (Seoul Primary -> Tokyo Secondary 재구성)
resource "aws_ssm_document" "aurora_failback_runbook" {
  name            = "Aurora-Failback-Runbook-Tokyo"
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-failback-runbook.yml")

  tags = local.common_tags
}

# SSM Automation Document - Disaster Failover (Seoul 리전 전체 장애 시 Tokyo를 독립 Primary로 승격)
resource "aws_ssm_document" "aurora_disaster_failover_runbook" {
  name            = "Aurora-Disaster-Failover-Runbook-Tokyo"
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-disaster-failover-runbook.yml")

  tags = local.common_tags
}
