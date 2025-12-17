locals {
  kakao_lambda_name = "dr-kakao-notifier"
  email_lambda_name = "dr-email-notifier"
}

resource "aws_sns_topic" "dr_alerts" {
  name = "dr-alerts"
}

data "archive_file" "kakao_notifier" {
  type        = "zip"
  source_file = "${path.module}/lambda/kakao-notifier.js"
  output_path = "${path.module}/lambda/kakao-notifier.zip"
}

data "aws_region" "current" {}

data "aws_ssm_parameter" "ses_sender" {
  count = var.ses_sender_ssm_path != "" ? 1 : 0
  name  = var.ses_sender_ssm_path
}

data "aws_ssm_parameter" "ses_recipients" {
  count = var.ses_recipients_ssm_path != "" ? 1 : 0
  name  = var.ses_recipients_ssm_path
}

resource "aws_iam_role" "kakao_notifier" {
  name = "${local.kakao_lambda_name}-role"

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

resource "aws_iam_role_policy" "kakao_notifier" {
  name = "${local.kakao_lambda_name}-policy"
  role = aws_iam_role.kakao_notifier.id

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
      }
    ]
  })
}

resource "aws_lambda_function" "kakao_notifier" {
  function_name = local.kakao_lambda_name
  role          = aws_iam_role.kakao_notifier.arn
  handler       = "kakao-notifier.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.kakao_notifier.output_path
  source_code_hash = data.archive_file.kakao_notifier.output_base64sha256

  timeout = 10

  environment {
    variables = {
      KAKAO_API_URL    = var.kakao_api_url
      KAKAO_API_KEY    = var.kakao_api_key
      KAKAO_CHANNEL_ID = var.kakao_channel_id
      KAKAO_TEMPLATE_ID = var.kakao_template_id
    }
  }
}

resource "aws_cloudwatch_log_group" "kakao_notifier" {
  name              = "/aws/lambda/${aws_lambda_function.kakao_notifier.function_name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "sns_invoke_kakao" {
  statement_id  = "AllowSnsInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kakao_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.dr_alerts.arn
}

resource "aws_sns_topic_subscription" "kakao_lambda_sub" {
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.kakao_notifier.arn

  depends_on = [aws_lambda_permission.sns_invoke_kakao]
}

data "archive_file" "email_notifier" {
  type        = "zip"
  source_file = "${path.module}/lambda/email-notifier.js"
  output_path = "${path.module}/lambda/email-notifier.zip"
}

resource "aws_iam_role" "email_notifier" {
  name = "${local.email_lambda_name}-role"

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

resource "aws_iam_role_policy" "email_notifier" {
  name = "${local.email_lambda_name}-policy"
  role = aws_iam_role.email_notifier.id

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
          "ses:SendEmail",
          "ses:SendTemplatedEmail"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_ses_template" "dr_alert" {
  name    = var.ses_template_name
  subject = var.ses_template_subject
  html    = var.ses_template_html
  text    = "알람: {{AlarmName}} 상태: {{NewStateValue}} 설명: {{AlarmDescription}} 시간: {{StateChangeTime}}"
}

resource "aws_lambda_function" "email_notifier" {
  function_name = local.email_lambda_name
  role          = aws_iam_role.email_notifier.arn
  handler       = "email-notifier.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.email_notifier.output_path
  source_code_hash = data.archive_file.email_notifier.output_base64sha256

  timeout = 10

  environment {
    variables = {
      SES_SENDER      = var.ses_sender_ssm_path != "" ? data.aws_ssm_parameter.ses_sender[0].value : var.ses_sender
      SES_RECIPIENTS  = var.ses_recipients_ssm_path != "" ? data.aws_ssm_parameter.ses_recipients[0].value : join(",", var.ses_recipients)
      WRITER_HINT     = "Seoul"
      ACTION_HINT     = "Failover 검토 필요"
    }
  }
}

resource "aws_cloudwatch_log_group" "email_notifier" {
  name              = "/aws/lambda/${aws_lambda_function.email_notifier.function_name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "sns_invoke_email" {
  statement_id  = "AllowSnsInvokeEmail"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_notifier.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.dr_alerts.arn
}

resource "aws_sns_topic_subscription" "email_lambda_sub" {
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_notifier.arn

  depends_on = [aws_lambda_permission.sns_invoke_email]
}
