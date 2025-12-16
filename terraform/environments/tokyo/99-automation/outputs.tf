output "iam_role_arn" {
  description = "SSM Automation Aurora 페일오버/페일백용 IAM 역할 ARN"
  value       = module.aurora_automation.iam_role_arn
}

output "iam_role_name" {
  description = "SSM Automation IAM 역할 이름"
  value       = module.aurora_automation.iam_role_name
}

output "failover_document_name" {
  description = "Aurora 페일오버 SSM Automation Document 이름"
  value       = aws_ssm_document.aurora_failover_runbook.name
}

output "failback_document_name" {
  description = "Aurora 페일백 SSM Automation Document 이름"
  value       = aws_ssm_document.aurora_failback_runbook.name
}

output "disaster_failover_document_name" {
  description = "Aurora 재해 페일오버 SSM Automation Document 이름 (Seoul 전체 장애 시)"
  value       = aws_ssm_document.aurora_disaster_failover_runbook.name
}

# =============================================================================
# Disaster Failover API Outputs
# =============================================================================

output "disaster_failover_api_url" {
  description = "재해 복구 런북 실행 API URL (POST 요청)"
  value       = "${aws_apigatewayv2_api.disaster_failover_api.api_endpoint}/execute-failover"
}

output "disaster_failover_api_key_parameter" {
  description = "API Key가 저장된 SSM Parameter 이름 (aws ssm get-parameter --name <name> --with-decryption --query Parameter.Value --output text 로 조회)"
  value       = aws_ssm_parameter.disaster_failover_api_key.name
}

output "disaster_failover_api_usage" {
  description = "API 호출 예시"
  value       = <<-EOT
    # API Key 조회
    API_KEY=$(aws ssm get-parameter --name "${aws_ssm_parameter.disaster_failover_api_key.name}" --with-decryption --query Parameter.Value --output text --region ap-northeast-1)

    # 런북 실행 (curl)
    curl -X POST "${aws_apigatewayv2_api.disaster_failover_api.api_endpoint}/execute-failover" \
      -H "X-Api-Key: $API_KEY" \
      -H "Content-Type: application/json"
  EOT
}

# =============================================================================
# TEST API Outputs
# =============================================================================

output "disaster_failover_test_api_url" {
  description = "[TEST] 테스트용 API URL - 실제 DB 작업 없이 플로우만 테스트"
  value       = "${aws_apigatewayv2_api.disaster_failover_api.api_endpoint}/test-failover"
}

output "disaster_failover_test_document_name" {
  description = "[TEST] 테스트용 SSM Automation Document 이름"
  value       = aws_ssm_document.aurora_disaster_failover_test_runbook.name
}

output "disaster_failover_test_usage" {
  description = "[TEST] 테스트 API 호출 예시"
  value       = <<-EOT
    # API Key 조회
    API_KEY=$(aws ssm get-parameter --name "${aws_ssm_parameter.disaster_failover_api_key.name}" --with-decryption --query Parameter.Value --output text --region ap-northeast-1)

    # 테스트 런북 실행 (실제 DB 작업 없음)
    curl -X POST "${aws_apigatewayv2_api.disaster_failover_api.api_endpoint}/test-failover" \
      -H "X-Api-Key: $API_KEY" \
      -H "Content-Type: application/json"
  EOT
}
