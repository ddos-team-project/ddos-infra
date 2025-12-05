###############################################
# tokyo/02-data 전용 변수 정의
###############################################

variable "account_api_db_rotation_lambda_arn" {
  description = "Account API DB Password Rotation Lambda ARN (없으면 빈 문자열)"
  type        = string
  default     = ""
}
