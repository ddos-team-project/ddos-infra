data "archive_file" "tokyo_traffic_ratio" {
  type        = "zip"
  source_file = "${path.module}/lambda/tokyo-traffic-ratio.js"
  output_path = "${path.module}/lambda/tokyo-traffic-ratio.zip"
}

resource "aws_iam_role" "tokyo_traffic_ratio" {
  name = "tokyo-traffic-ratio-role"

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

resource "aws_iam_role_policy" "tokyo_traffic_ratio" {
  name = "tokyo-traffic-ratio-policy"
  role = aws_iam_role.tokyo_traffic_ratio.id

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
          "cloudwatch:GetMetricData"
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
            "cloudwatch:namespace" : ["DR/Traffic"]
          }
        }
      }
    ]
  })
}

resource "aws_lambda_function" "tokyo_traffic_ratio" {
  function_name = "tokyo-traffic-ratio"
  role          = aws_iam_role.tokyo_traffic_ratio.arn
  handler       = "tokyo-traffic-ratio.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.tokyo_traffic_ratio.output_path
  source_code_hash = data.archive_file.tokyo_traffic_ratio.output_base64sha256

  timeout = 60
  environment {
    variables = {
      SEOUL_ASG_NAME           = local.seoul_asg_name
      TOKYO_ASG_NAME           = local.tokyo_asg_name
      SEOUL_REGION             = "ap-northeast-2"
      TOKYO_REGION             = "ap-northeast-1"
      METRIC_REGION            = "ap-northeast-2"
      LOOKBACK_MINUTES         = "5"
      PERIOD_SECONDS           = "60"
      METRIC_NAMESPACE         = "DR/Traffic"
      METRIC_NAME              = "TokyoTrafficRatio"
      METRIC_DIMENSION_NAME    = "Service"
      METRIC_DIMENSION_VALUE   = "healthcheck-api"
    }
  }
}

resource "aws_cloudwatch_log_group" "tokyo_traffic_ratio" {
  name              = "/aws/lambda/${aws_lambda_function.tokyo_traffic_ratio.function_name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_event_rule" "tokyo_traffic_ratio" {
  name                = "tokyo-traffic-ratio-schedule"
  schedule_expression = var.tokyo_traffic_ratio_schedule
}

resource "aws_cloudwatch_event_target" "tokyo_traffic_ratio" {
  rule      = aws_cloudwatch_event_rule.tokyo_traffic_ratio.name
  target_id = "tokyo-traffic-ratio"
  arn       = aws_lambda_function.tokyo_traffic_ratio.arn
}

resource "aws_lambda_permission" "tokyo_traffic_ratio_events" {
  statement_id  = "AllowExecutionFromCloudWatchEventsTokyoTraffic"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tokyo_traffic_ratio.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.tokyo_traffic_ratio.arn
}

resource "aws_cloudwatch_metric_alarm" "tokyo_traffic_ratio_high" {
  alarm_name          = "tokyo-트래픽비율-50-초과"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 0.5
  period              = 60
  statistic           = "Average"
  namespace           = "DR/Traffic"
  metric_name         = "TokyoTrafficRatio"
  dimensions = {
    Service = "healthcheck-api"
  }
  treat_missing_data = "notBreaching"
  alarm_description  = "Tokyo traffic ratio > 50% (도쿄/서울 합계 대비)"
  alarm_actions      = [aws_sns_topic.dr_alerts.arn]
  ok_actions         = [aws_sns_topic.dr_alerts.arn]
}
