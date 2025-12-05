###############################################
# seoul/02-data 전용 변수 정의
###############################################

# Aurora Rotation Lambda ARN
# - AWS에서 미리 생성한 Secrets Manager Rotation Lambda ARN
# - (예: 콘솔에서 RDS Single user rotation 템플릿으로 만든 Lambda)
variable "account_api_db_rotation_lambda_arn" {
  description = "Account API DB Password Rotation Lambda ARN (없으면 빈 문자열)"
  type        = string
  default     = "" # 일단 비워 두고, 나중에 Lambda 만들고 채워 넣어도 됨
}
