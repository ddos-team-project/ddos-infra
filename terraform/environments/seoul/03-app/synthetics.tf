data "aws_iam_policy_document" "synthetics_assume" {
  count = var.enable_synthetics_canary ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "synthetics.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "synthetics_canary" {
  count              = var.enable_synthetics_canary ? 1 : 0
  name               = "${local.name_prefix}-synthetics"
  assume_role_policy = data.aws_iam_policy_document.synthetics_assume[0].json
}

resource "aws_iam_role_policy_attachment" "synthetics_canary_basic" {
  count      = var.enable_synthetics_canary ? 1 : 0
  role       = aws_iam_role.synthetics_canary[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "synthetics_canary_fullaccess" {
  count      = var.enable_synthetics_canary ? 1 : 0
  role       = aws_iam_role.synthetics_canary[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchSyntheticsFullAccess"
}

data "archive_file" "synthetics_healthcheck" {
  count       = var.enable_synthetics_canary ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/synthetics/healthcheck.js"
  output_path = "${path.module}/synthetics/healthcheck.zip"
}

resource "aws_s3_object" "synthetics_code" {
  count = var.enable_synthetics_canary ? 1 : 0

  bucket = var.synthetics_artifact_bucket
  key    = "synthetics/${local.name_prefix}/healthcheck.zip"
  source = data.archive_file.synthetics_healthcheck[0].output_path
  etag   = data.archive_file.synthetics_healthcheck[0].output_base64sha256
}

resource "aws_synthetics_canary" "health" {
  count                 = var.enable_synthetics_canary ? 1 : 0
  name                  = local.synthetics_canary_name
  artifact_s3_location  = "${local.synthetics_artifact_prefix}/"
  execution_role_arn    = aws_iam_role.synthetics_canary[0].arn
  handler               = "healthcheck.handler"
  runtime_version       = "syn-nodejs-puppeteer-6.2"
  start_canary          = true
  success_retention_period = 7
  failure_retention_period = 30

  s3_bucket = var.synthetics_artifact_bucket
  s3_key    = aws_s3_object.synthetics_code[0].key

  schedule {
    expression = var.synthetics_schedule_expression
  }

  run_config {
    timeout_in_seconds = 30
    environment_variables = {
      TARGET_URL = local.synthetics_canary_url
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "synthetics_health" {
  count                = var.enable_synthetics_canary ? 1 : 0
  alarm_name           = "${local.name_prefix}-synthetics-failed"
  comparison_operator  = "LessThanThreshold"
  evaluation_periods   = 1
  threshold            = 100
  period               = 300
  statistic            = "Average"
  namespace            = "CloudWatchSynthetics"
  metric_name          = "SuccessPercent"
  dimensions = {
    CanaryName = aws_synthetics_canary.health[0].name
  }
  treat_missing_data = "breaching"
  alarm_description  = "Synthetics /health canary failed"
  alarm_actions      = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
  ok_actions         = var.alarm_topic_arn == null ? [] : [var.alarm_topic_arn]
}
