module "aurora_automation" {
  source = "../../../modules/aurora-automation"

  region_name                = "Seoul"
  environment                = var.environment
  failover_runbook_content   = file("${path.module}/aurora-failover-runbook.yml")
  failback_runbook_content   = file("${path.module}/aurora-failback-runbook.yml")
  db_endpoint_parameter_name = var.db_endpoint_parameter_name

  tags = local.common_tags
}
