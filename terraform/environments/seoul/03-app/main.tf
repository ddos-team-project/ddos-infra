#############################################################
# 서울 리전 App 계층
# Healthcheck API Docker 컨테이너를 EC2 + ASG + ALB로 운영
# DB/Aurora 및 Networking은 Remote State 참조
#############################################################

terraform {
  required_version = ">= 1.6.0"
  backend "s3" {
    bucket = "diehard-ddos-tf-state-lock" # 🔥 실제 값
    key    = "seoul/03-app/healthcheck-api.tfstate"
    region = "ap-northeast-2"
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# 🔹 01-network remote_state → VPC / Subnets
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/01-network/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# 🔹 02-data remote_state → Aurora endpoint
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "diehard-ddos-tf-state-lock"
    key    = "seoul/02-data/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "healthcheck-api-seoul"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  # ❗ 여기 2줄이 핵심
  app_subnet_ids = data.terraform_remote_state.network.outputs.app_subnets
  alb_subnet_ids = data.terraform_remote_state.network.outputs.public_subnets

  db_host = "dh-prod-db-seoul-aurora-primary.cluster-clg0eecwg923.ap-northeast-2.rds.amazonaws.com"


  ecr_repository = "dh-prod-t1-ecr-healthcheck-api"
  image_tag      = "dev"
  image_uri      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com/${local.ecr_repository}:${local.image_tag}"
}

# DB 비밀번호는 tfvars 또는 CI/CD에서 안전하게 주입
variable "aurora_app_password" {
  type      = string
  sensitive = true
  default   = ""
}

module "healthcheck_api_app" {
  source = "../../../modules/app-ec2-asg"

  name           = local.name_prefix
  vpc_id         = local.vpc_id
  app_subnet_ids = local.app_subnet_ids
  alb_subnet_ids = local.alb_subnet_ids

  aws_region = "ap-northeast-2"

  image_uri = local.image_uri

  instance_type    = "t3.medium"
  min_size         = 2
  max_size         = 6
  desired_capacity = 2
  key_name         = aws_key_pair.healthcheck_key.key_name


  service_name   = "ddos-healthcheck-api"
  region_label   = "seoul"
  app_env        = "prod"
  app_port       = 8080
  container_port = 3000

  db_host     = local.db_host
  db_name     = "ddos_noncore"
  db_user     = "admin"
  db_password = "SuperSecretPassword123!"

  tags = {
    Project = "ddos"
    Env     = "prod"
    Region  = "seoul"
    System  = "healthcheck-api"


  }

}

# 출력 → 운영/검증에 유용
output "healthcheck_alb_dns_name" {
  value = module.healthcheck_api_app.alb_dns_name
}

output "healthcheck_app_sg_id" {
  value = module.healthcheck_api_app.app_sg_id
}

resource "aws_key_pair" "healthcheck_key" {
  key_name   = "healthcheck-ssh-20251209"
  public_key = file("C:/Users/Admin/.ssh/mykey.pub") # ← USERNAME을 실제 계정명으로 바꿔야 함
}



# #############################################################
# # 🔹 Bastion 접속용 Amazon Linux 2023 AMI 선언 (필수)
# #############################################################
# data "aws_ami" "bastion_ami_2023" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-*-x86_64"]
#   }
# }

# resource "aws_iam_role" "bastion_role" {
#   name               = "${local.name_prefix}-bastion-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action    = "sts:AssumeRole"
#       Effect    = "Allow"
#       Principal = { Service = "ec2.amazonaws.com" }
#     }]
#   })
#   tags = {
#     Name    = "${local.name_prefix}-bastion-role"
#     Project = "ddos"
#     Env     = "prod"
#     Region  = "seoul"
#     System  = "bastion-test"
#   }
# }

# resource "aws_iam_policy" "bastion_ecr_policy" {
#   name = "${local.name_prefix}-bastion-ecr-policy"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect   = "Allow"
#         Action   = [
#           "ecr:GetAuthorizationToken",
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "bastion_attach" {
#   role       = aws_iam_role.bastion_role.name
#   policy_arn = aws_iam_policy.bastion_ecr_policy.arn
# }

# resource "aws_iam_instance_profile" "bastion_profile" {
#   name = "${local.name_prefix}-bastion-profile"
#   role = aws_iam_role.bastion_role.name
# }

# resource "aws_security_group" "bastion" {
#   name        = "${local.name_prefix}-bastion-sg"
#   description = "SSH bastion for testing"
#   vpc_id      = local.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # 테스트 중이라 풀오픈
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name    = "${local.name_prefix}-bastion"
#     Project = "ddos"
#     Env     = "prod"
#     Region  = "seoul"
#     System  = "bastion-test"
#   }
# }

# resource "aws_instance" "bastion" {
#   ami                         = data.aws_ami.bastion_ami_2023.id
#   instance_type               = "t3.micro"
#   subnet_id                   = local.alb_subnet_ids[0]
#   vpc_security_group_ids      = [aws_security_group.bastion.id]
#   associate_public_ip_address = true
#   key_name                    = aws_key_pair.healthcheck_key.key_name
#   iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name

#   user_data = <<-EOF
#     #!/bin/bash
#     set -xe
#     dnf update -y

#     # Docker 설치 (폴백 포함)
#     dnf install -y docker || dnf install -y moby-engine moby-cli
#     systemctl enable --now docker
#     usermod -aG docker ec2-user

#     # AWS CLI 없으면 설치
#     if ! command -v aws &>/dev/null; then
#       dnf install -y awscli
#     fi

#     # 테스트용 환경 변수 (앱 ASG와 동일하게 맞춤)
#     IMAGE_URI="${local.image_uri}"
#     SERVICE_NAME="ddos-healthcheck-api"
#     APP_PORT=8080
#     CONTAINER_PORT=3000
#     REGION_LABEL="seoul"
#     APP_ENV="prod"
#     DB_HOST="${local.db_host}"
#     DB_PORT=3306
#     DB_NAME="ddos_noncore"
#     DB_USER="admin"
#     DB_PASSWORD="SuperSecretPassword123!"

#     IMAGE_URI_REGISTRY=$(echo "$${IMAGE_URI}" | cut -d/ -f1)

#     # ECR 로그인
#     aws ecr get-login-password --region ap-northeast-2 \
#       | docker login --username AWS --password-stdin "$${IMAGE_URI_REGISTRY}"

#     # 기존 컨테이너 정리
#     docker stop "$${SERVICE_NAME}" 2>/dev/null || true
#     docker rm "$${SERVICE_NAME}" 2>/dev/null || true

#     # 최신 이미지 pull
#     docker pull "$${IMAGE_URI}"

#     # 컨테이너 실행 (헬스체크 동일 조건)
#     docker run -d \
#       --name "$${SERVICE_NAME}" \
#       --restart unless-stopped \
#       -p $${APP_PORT}:$${CONTAINER_PORT} \
#       -e SERVICE_NAME="$${SERVICE_NAME}" \
#       -e REGION="$${REGION_LABEL}" \
#       -e APP_ENV="$${APP_ENV}" \
#       -e DB_HOST="$${DB_HOST}" \
#       -e DB_PORT="$${DB_PORT}" \
#       -e DB_NAME="$${DB_NAME}" \
#       -e DB_USER="$${DB_USER}" \
#       -e DB_PASSWORD="$${DB_PASSWORD}" \
#       "$${IMAGE_URI}"

#     # 필요 시 DB 클라이언트
#     dnf install -y mariadb
#   EOF

#   tags = {
#     Name    = "${local.name_prefix}-bastion"
#     Project = "ddos"
#     Env     = "prod"
#     Region  = "seoul"
#     System  = "bastion-test"
#   }
# }
