locals {
  cwagent_config = {
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            # System logs
            {
              file_path       = "/var/log/messages"
              log_group_name  = "/${var.env}/${var.project}/${var.tier}/${var.region}/system/messages"
              log_stream_name = "{instance_id}-messages"
            },
            {
              file_path       = "/var/log/secure"
              log_group_name  = "/${var.env}/${var.project}/${var.tier}/${var.region}/system/secure"
              log_stream_name = "{instance_id}-secure"
            },
            {
              file_path       = "/var/log/cloud-init.log"
              log_group_name  = "/${var.env}/${var.project}/${var.tier}/${var.region}/system/cloud-init"
              log_stream_name = "{instance_id}-cloud-init"
            },
            {
              file_path       = "/var/log/docker.log"
              log_group_name  = "/${var.env}/${var.project}/${var.tier}/${var.region}/system/docker"
              log_stream_name = "{instance_id}-docker"
            },

            # Application Container logs
            {
              file_path       = "/var/lib/docker/containers/*/*.log"
              log_group_name  = "/${var.env}/${var.project}/${var.tier}/${var.region}/${var.service_name}/app"
              log_stream_name = "{instance_id}-app"
              timezone        = "Local"
            }
          ]
        }
      }
    }
  }
}

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name        = "/${var.env}/${var.project}/${var.tier}/${var.region}/cloudwatch/config"
  description = "Dynamic CloudWatch Agent config for ${var.env}-${var.region}-${var.tier}"
  type        = "String"

  value = jsonencode(local.cwagent_config)

  tags = merge(
    local.tags,
    {
      Name    = "${var.project}-${var.env}-${var.region}-${var.tier}-cwagent-config"
      Purpose = "cloudwatch-agent-config"
    }
  )
}
