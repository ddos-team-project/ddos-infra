# IAM Role 생성 (공통 모듈)
module "aurora_automation" {
  source = "../../../modules/aurora-automation"

  region_name = "Seoul"
  environment = var.environment

  tags = local.common_tags
}

# SSM Automation Document - Failover (Tokyo 장애 시 Seoul 독립 운영)
resource "aws_ssm_document" "aurora_failover_runbook" {
  name            = "Aurora-Failover-Runbook-Seoul"
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-failover-runbook.yml")

  tags = local.common_tags
}

# SSM Automation Document - Failback (Tokyo Primary -> Seoul Primary)
resource "aws_ssm_document" "aurora_failback_runbook" {
  name            = "Aurora-Failback-Runbook-Seoul"
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-failback-runbook.yml")

  tags = local.common_tags
}

# Seoul은 Primary이므로 Disaster Failover 런북 불필요
