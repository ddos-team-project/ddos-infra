module "aurora_automation" {
  source = "../../../modules/aurora-automation"

  region_name                       = "Seoul"
  environment                       = var.environment
  failover_runbook_content          = file("${path.module}/aurora-failover-runbook.yml")
  failback_runbook_content          = file("${path.module}/aurora-failback-runbook.yml")
  disaster_failover_runbook_content = file("${path.module}/aurora-disaster-failover-runbook.yml")
  db_endpoint_parameter_name        = var.db_endpoint_parameter_name

  # Disaster Recovery Failback Runbooks (Seoul 복구 후 페일백)
  disaster_recovery_verify_content             = file("${path.module}/disaster-recovery-1-verify.yml")
  disaster_recovery_create_cluster_content     = file("${path.module}/disaster-recovery-2-create-cluster.yml")
  disaster_recovery_add_secondary_content      = file("${path.module}/disaster-recovery-3-add-secondary.yml")
  disaster_recovery_verify_replication_content = file("${path.module}/disaster-recovery-4-verify-replication.yml")

  tags = local.common_tags
}
