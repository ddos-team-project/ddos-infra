resource "aws_ssm_parameter" "cwagent_config" {
  name        = var.cwagent_ssm_name
  type        = "String"
  description = "CloudWatch Agent configuration for ${var.service_name}"

  value = templatefile("${path.module}/cwagent-config.json", {
    env          = var.env
    project      = var.project
    tier         = var.tier
    region       = var.region
    service_name = var.service_name
  })

  overwrite = true
}
