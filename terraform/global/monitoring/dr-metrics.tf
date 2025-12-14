data "archive_file" "dr_metrics_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/dr-metrics.js"
  output_path = "${path.module}/lambda/dr-metrics.zip"
}

resource "aws_iam_role" "dr_metrics" {
  name = "dr-writer-active-metrics-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : { Service : "lambda.amazonaws.com" },
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "dr_metrics" {
  name = "dr-writer-active-metrics-policy"
  role = aws_iam_role.dr_metrics.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "cloudwatch:PutMetricData"
        ],
        Resource : "*",
        Condition : {
          StringEquals : {
            "cloudwatch:namespace" : [local.metric_namespace]
          }
        }
      },
      {
        Effect : "Allow",
        Action : [
          "rds:DescribeDBClusters"
        ],
        Resource : [
          data.terraform_remote_state.seoul_data.outputs.cluster_arn,
          data.terraform_remote_state.tokyo_data.outputs.cluster_arn
        ]
      },
      {
        Effect : "Allow",
        Action : [
          "route53:ListResourceRecordSets"
        ],
        Resource : [
          var.route53_zone_id != "" ? "arn:aws:route53:::hostedzone/${var.route53_zone_id}" : "*"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "dr_metrics" {
  function_name = "dr-writer-active-metrics"
  role          = aws_iam_role.dr_metrics.arn
  handler       = "dr-metrics.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.dr_metrics_lambda.output_path
  source_code_hash = data.archive_file.dr_metrics_lambda.output_base64sha256

  timeout = 30
  environment {
    variables = {
      METRIC_NAMESPACE     = local.metric_namespace
      METRIC_DIMENSION     = local.metric_dimension_system
      PRIMARY_CLUSTER_ID   = local.seoul_cluster_id
      SECONDARY_CLUSTER_ID = local.tokyo_cluster_id
      PRIMARY_REGION       = local.writer_region_primary
      SECONDARY_REGION     = local.writer_region_secondary
      PRIMARY_VALUE        = tostring(local.writer_region_value_map.primary)
      SECONDARY_VALUE      = tostring(local.writer_region_value_map.secondary)
      ROUTE53_ZONE_ID      = var.route53_zone_id
      ROUTE53_RECORD_NAME  = var.route53_record_name
    }
  }
}

resource "aws_cloudwatch_log_group" "dr_metrics" {
  name              = "/aws/lambda/${aws_lambda_function.dr_metrics.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_event_rule" "dr_metrics" {
  name                = "dr-writer-active-metrics-schedule"
  schedule_expression = var.dr_metrics_schedule
}

resource "aws_cloudwatch_event_target" "dr_metrics" {
  rule      = aws_cloudwatch_event_rule.dr_metrics.name
  target_id = "dr-writer-active-metrics"
  arn       = aws_lambda_function.dr_metrics.arn
}

resource "aws_lambda_permission" "dr_metrics_events" {
  statement_id  = "AllowExecutionFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_metrics.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dr_metrics.arn
}
