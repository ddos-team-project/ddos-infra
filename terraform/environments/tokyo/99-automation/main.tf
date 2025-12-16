# IAM Role 생성 (공통 모듈)
module "aurora_automation" {
  source = "../../../modules/aurora-automation"

  region_name = "Tokyo"
  environment = var.environment

  tags = local.common_tags
}

# SSM Automation Document - Failover (Seoul 장애 시 Tokyo 독립 운영)
resource "aws_ssm_document" "aurora_failover_runbook" {
  name            = "Aurora-Failover-Runbook-Tokyo"
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-failover-runbook.yml")

  tags = local.common_tags
}

# SSM Automation Document - Failback (Seoul Primary -> Tokyo Secondary 재구성)
resource "aws_ssm_document" "aurora_failback_runbook" {
  name            = "Aurora-Failback-Runbook-Tokyo"
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-failback-runbook.yml")

  tags = local.common_tags
}

# SSM Automation Document - Disaster Failover (Seoul 리전 전체 장애 시 Tokyo를 독립 Primary로 승격)
resource "aws_ssm_document" "aurora_disaster_failover_runbook" {
  name            = "Aurora-Disaster-Failover-Runbook-Tokyo"
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-disaster-failover-runbook.yml")

  tags = local.common_tags
}

# =============================================================================
# Disaster Failover Trigger API (API Gateway + Lambda)
# 관리자가 URL을 통해 재해 복구 런북을 실행할 수 있도록 함
# =============================================================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Lambda 실행용 IAM Role
resource "aws_iam_role" "disaster_failover_lambda_role" {
  name = "disaster-failover-lambda-role-tokyo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Lambda 기본 실행 정책 (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.disaster_failover_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SSM Automation 실행 권한
resource "aws_iam_role_policy" "lambda_ssm_automation_policy" {
  name = "ssm-automation-execution-policy"
  role = aws_iam_role.disaster_failover_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution",
          "ssm:DescribeAutomationExecutions"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:automation-definition/${aws_ssm_document.aurora_disaster_failover_runbook.name}:*",
          "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:automation-execution/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = module.aurora_automation.iam_role_arn
      }
    ]
  })
}

# Lambda 함수용 ZIP 파일 생성
data "archive_file" "disaster_failover_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/disaster_failover_trigger.py"
  output_path = "${path.module}/lambda/disaster_failover_trigger.zip"
}

# Lambda 함수
resource "aws_lambda_function" "disaster_failover_trigger" {
  function_name = "disaster-failover-trigger-tokyo"
  description   = "Seoul 리전 장애 시 Tokyo Aurora DB 페일오버 런북 실행 트리거"

  filename         = data.archive_file.disaster_failover_lambda_zip.output_path
  source_code_hash = data.archive_file.disaster_failover_lambda_zip.output_base64sha256
  handler          = "disaster_failover_trigger.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  role = aws_iam_role.disaster_failover_lambda_role.arn

  environment {
    variables = {
      SSM_DOCUMENT_NAME   = aws_ssm_document.aurora_disaster_failover_runbook.name
      AUTOMATION_ROLE_ARN = module.aurora_automation.iam_role_arn
    }
  }

  tags = local.common_tags
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "disaster_failover_api" {
  name          = "disaster-failover-api-tokyo"
  protocol_type = "HTTP"
  description   = "Seoul 리전 장애 시 Tokyo Aurora DB 페일오버 런북 실행 API"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["Content-Type", "X-Api-Key"]
    max_age       = 300
  }

  tags = local.common_tags
}

# Lambda 통합
resource "aws_apigatewayv2_integration" "disaster_failover_integration" {
  api_id             = aws_apigatewayv2_api.disaster_failover_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.disaster_failover_trigger.invoke_arn
  integration_method = "POST"
}

# API 라우트 (Authorizer 연결)
resource "aws_apigatewayv2_route" "disaster_failover_route" {
  api_id    = aws_apigatewayv2_api.disaster_failover_api.id
  route_key = "POST /execute-failover"
  target    = "integrations/${aws_apigatewayv2_integration.disaster_failover_integration.id}"

  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_key_authorizer.id
}

# API 스테이지 (자동 배포)
resource "aws_apigatewayv2_stage" "disaster_failover_stage" {
  api_id      = aws_apigatewayv2_api.disaster_failover_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }

  tags = local.common_tags
}

# API Gateway 로그 그룹
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/api-gateway/disaster-failover-api-tokyo"
  retention_in_days = 30

  tags = local.common_tags
}

# Lambda 실행 권한 (API Gateway가 Lambda를 호출할 수 있도록)
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disaster_failover_trigger.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.disaster_failover_api.execution_arn}/*/*"
}

# =============================================================================
# API Key 인증 (REST API로 변경하여 API Key 지원)
# HTTP API는 API Key를 기본 지원하지 않으므로 Lambda Authorizer 사용
# =============================================================================

# API Key를 환경변수로 저장 (SSM Parameter)
resource "random_password" "api_key" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "disaster_failover_api_key" {
  name        = "/ddos/disaster-failover/api-key"
  description = "Disaster Failover API Key"
  type        = "SecureString"
  value       = random_password.api_key.result

  tags = local.common_tags
}

# Lambda Authorizer 함수
resource "aws_lambda_function" "api_key_authorizer" {
  function_name = "disaster-failover-api-authorizer-tokyo"
  description   = "API Key 검증 Lambda Authorizer"

  filename = data.archive_file.authorizer_lambda_zip.output_path
  source_code_hash = data.archive_file.authorizer_lambda_zip.output_base64sha256
  handler  = "api_key_authorizer.lambda_handler"
  runtime  = "python3.12"
  timeout  = 10

  role = aws_iam_role.authorizer_lambda_role.arn

  environment {
    variables = {
      API_KEY_PARAMETER_NAME = aws_ssm_parameter.disaster_failover_api_key.name
    }
  }

  tags = local.common_tags
}

# Authorizer Lambda용 ZIP
data "archive_file" "authorizer_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/api_key_authorizer.py"
  output_path = "${path.module}/lambda/api_key_authorizer.zip"
}

# Authorizer Lambda IAM Role
resource "aws_iam_role" "authorizer_lambda_role" {
  name = "disaster-failover-authorizer-role-tokyo"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "authorizer_basic_execution" {
  role       = aws_iam_role.authorizer_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "authorizer_ssm_read" {
  name = "ssm-parameter-read-policy"
  role = aws_iam_role.authorizer_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = aws_ssm_parameter.disaster_failover_api_key.arn
      }
    ]
  })
}

# API Gateway Authorizer
resource "aws_apigatewayv2_authorizer" "api_key_authorizer" {
  api_id           = aws_apigatewayv2_api.disaster_failover_api.id
  authorizer_type  = "REQUEST"
  name             = "api-key-authorizer"
  authorizer_uri   = aws_lambda_function.api_key_authorizer.invoke_arn
  identity_sources = ["$request.header.X-Api-Key"]

  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
}

# Lambda Authorizer 실행 권한
resource "aws_lambda_permission" "authorizer_invoke" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_key_authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.disaster_failover_api.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.api_key_authorizer.id}"
}

# =============================================================================
# TEST 모드: 실제 DB 작업 없이 API 플로우 테스트용
# =============================================================================

# 테스트용 SSM Automation Document
resource "aws_ssm_document" "aurora_disaster_failover_test_runbook" {
  name            = "Aurora-Disaster-Failover-Test-Runbook-Tokyo"
  document_type   = "Automation"
  document_format = "YAML"

  content = file("${path.module}/aurora-disaster-failover-test-runbook.yml")

  tags = local.common_tags
}

# 테스트용 Lambda 함수
resource "aws_lambda_function" "disaster_failover_test_trigger" {
  function_name = "disaster-failover-test-trigger-tokyo"
  description   = "[TEST] Disaster Failover API 테스트용 - 실제 DB 작업 없음"

  filename         = data.archive_file.disaster_failover_test_lambda_zip.output_path
  source_code_hash = data.archive_file.disaster_failover_test_lambda_zip.output_base64sha256
  handler          = "disaster_failover_test_trigger.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  role = aws_iam_role.disaster_failover_lambda_role.arn

  environment {
    variables = {
      SSM_DOCUMENT_NAME   = aws_ssm_document.aurora_disaster_failover_test_runbook.name
      AUTOMATION_ROLE_ARN = module.aurora_automation.iam_role_arn
    }
  }

  tags = local.common_tags
}

# 테스트 Lambda용 ZIP
data "archive_file" "disaster_failover_test_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/disaster_failover_test_trigger.py"
  output_path = "${path.module}/lambda/disaster_failover_test_trigger.zip"
}

# 테스트용 Lambda 통합
resource "aws_apigatewayv2_integration" "disaster_failover_test_integration" {
  api_id             = aws_apigatewayv2_api.disaster_failover_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.disaster_failover_test_trigger.invoke_arn
  integration_method = "POST"
}

# 테스트용 API 라우트 (인증 필요)
resource "aws_apigatewayv2_route" "disaster_failover_test_route" {
  api_id    = aws_apigatewayv2_api.disaster_failover_api.id
  route_key = "POST /test-failover"
  target    = "integrations/${aws_apigatewayv2_integration.disaster_failover_test_integration.id}"

  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_key_authorizer.id
}

# 테스트 Lambda 실행 권한
resource "aws_lambda_permission" "api_gateway_test_invoke" {
  statement_id  = "AllowAPIGatewayTestInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disaster_failover_test_trigger.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.disaster_failover_api.execution_arn}/*/*"
}

# 테스트 런북 실행 권한 추가
resource "aws_iam_role_policy" "lambda_ssm_test_automation_policy" {
  name = "ssm-test-automation-execution-policy"
  role = aws_iam_role.disaster_failover_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:automation-definition/${aws_ssm_document.aurora_disaster_failover_test_runbook.name}:*",
          "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:automation-execution/*"
        ]
      }
    ]
  })
}
