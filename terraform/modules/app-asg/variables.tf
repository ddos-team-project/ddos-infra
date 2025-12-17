variable "name" {
  description = "앱 이름 프리픽스"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "app_subnet_ids" {
  description = "EC2가 배치될 서브넷 목록(보통 프라이빗 앱 서브넷)"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "ASG 최소 용량"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "ASG 최대 용량"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "ASG 희망 용량"
  type        = number
  default     = 2
}

variable "image_uri" {
  description = "ECR 이미지 전체 URI"
  type        = string
}

variable "ami_id" {
  description = "고정 AMI ID (null이면 Amazon Linux 2023을 조회)"
  type        = string
  default     = null
}

variable "aws_region" {
  description = "앱이 동작할 AWS 리전"
  type        = string
}

variable "service_name" {
  description = "서비스 이름 (SERVICE_NAME 환경변수)"
  type        = string
  default     = "ddos-healthcheck-api"
}

variable "app_env" {
  description = "애플리케이션 환경 (prod/stage/dev)"
  type        = string
  default     = "prod"
}

variable "region_label" {
  description = "앱에서 사용할 리전 라벨"
  type        = string
  default     = "seoul"
}

variable "container_port" {
  description = "컨테이너 내부 포트"
  type        = number
  default     = 3000
}

variable "app_port" {
  description = "EC2/TG에서 노출할 포트"
  type        = number
  default     = 8080
}

variable "enable_target_tracking" {
  description = "ASG 타깃 추적 기반 오토스케일 활성화 여부"
  type        = bool
  default     = false
}

variable "target_cpu_utilization" {
  description = "타깃 추적용 평균 CPU 사용률 목표(%) - 금융권 권장 40~50%"
  type        = number
  default     = 50
}

variable "estimated_instance_warmup" {
  description = "타깃 추적 정책에서 고려할 인스턴스 워밍업 시간(초)"
  type        = number
  default     = 300
}
#스트레스 테스트용 테스트 끝나면 false 로 바꾸고 다시 apply
variable "allow_stress_endpoint" {
  description = "컨테이너에 ALLOW_STRESS 환경변수를 주입해 /stress 엔드포인트를 활성화할지 여부"
  type        = bool
  default     = true
}

variable "db_host" {
  description = "Aurora 엔드포인트"
  type        = string
}

variable "db_port" {
  description = "Aurora 포트"
  type        = number
  default     = 3306
}

variable "db_name" {
  description = "Aurora DB 이름"
  type        = string
  default     = "ddos_noncore"
}

variable "db_user" {
  description = "Aurora 사용자"
  type        = string
  default     = "app_admin"
}

variable "db_password_ssm_path" {
  description = "SSM Parameter Store path for DB password (e.g. /ddos/aurora/password)"
  type        = string
}

variable "tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

variable "app_security_group_id" {
  description = "기존 앱 SG ID (null이면 모듈이 생성)"
  type        = string
  default     = null
}

variable "alb_security_group_id" {
  description = "앱 SG 생성 시 인입을 허용할 ALB SG ID"
  type        = string
  default     = null
}

variable "target_group_arns" {
  description = "ASG에 연결할 타깃그룹 ARN 목록"
  type        = list(string)
}

variable "key_name" {
  description = "EC2 키 페어 이름"
  type        = string
  default     = null
}

variable "app_sg_ids" {
  description = "ASG 인스턴스에 부착할 SG ID 목록(없으면 빈 리스트)"
  type        = list(string)
  default     = []
}


variable "idc_host" {
  description = "IDC 서버 IP (VPN 연결용)"
  type        = string
  default     = "192.168.0.10"
}

variable "idc_port" {
  description = "IDC 서버 포트"
  type        = number
  default     = 3000
}


variable "cwagent_ssm_name" {
  description = "SSM parameter name containing CloudWatch Agent config"
  type        = string
}

# ============================================
# 금융권 표준 스케일링 설정
# ============================================

variable "health_check_grace_period" {
  description = "ASG 헬스체크 유예 시간(초) - 금융권 권장 300초 이상"
  type        = number
  default     = 300
}

variable "disable_scale_in" {
  description = "Scale-In 비활성화 여부 (금융권 보수적 운영용)"
  type        = bool
  default     = false
}

variable "enable_alb_request_scaling" {
  description = "ALB 요청 수 기반 Target Tracking 활성화"
  type        = bool
  default     = false
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix (ALB 요청 수 스케일링용)"
  type        = string
  default     = ""
}

variable "target_group_arn_suffix" {
  description = "Target Group ARN suffix (ALB 요청 수 스케일링용)"
  type        = string
  default     = ""
}

variable "target_requests_per_target" {
  description = "타깃당 요청 수 목표값 - 부하테스트 결과의 70~80% 권장"
  type        = number
  default     = 1000
}

variable "enable_rps_scaling" {
  description = "RequestCountPerTarget 기반 스텝 스케일링 활성화 여부"
  type        = bool
  default     = true
}

variable "scale_out_rps_threshold" {
  description = "Scale-Out 기준 RequestCountPerTarget 임계치 (req/min)"
  type        = number
  default     = 300
}

variable "scale_out_evaluation_periods" {
  description = "Scale-Out 연속 평가 기간(분 단위, CloudWatch period 수)"
  type        = number
  default     = 3
}

variable "scale_in_rps_threshold" {
  description = "Scale-In 기준 RequestCountPerTarget 임계치 (req/min)"
  type        = number
  default     = 150
}

variable "scale_in_evaluation_periods" {
  description = "Scale-In 연속 평가 기간(분 단위, CloudWatch period 수)"
  type        = number
  default     = 10
}

variable "rps_metric_period" {
  description = "CloudWatch RequestCountPerTarget 메트릭 수집 주기(초)"
  type        = number
  default     = 60
}
