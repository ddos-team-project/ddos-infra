module "aurora_automation" {
  source = "../../../modules/aurora-automation"

  region_name                       = "Tokyo"
  environment                       = var.environment
  failover_runbook_content          = file("${path.module}/aurora-failover-runbook.yml")
  failback_runbook_content          = file("${path.module}/aurora-failback-runbook.yml")
  disaster_failover_runbook_content = file("${path.module}/aurora-disaster-failover-runbook.yml")
  db_endpoint_parameter_name        = var.db_endpoint_parameter_name

  # Tokyo Disaster Recovery Failback Runbooks (Seoul 복구 후 페일백 준비)
  disaster_recovery_prepare_failback_content  = file("${path.module}/disaster-recovery-prepare-failback.yml")
  disaster_recovery_recreate_global_content   = file("${path.module}/disaster-recovery-recreate-global.yml")

  tags = local.common_tags
}
