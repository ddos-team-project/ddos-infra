#!/bin/bash
set -xe

# SELinux kernel reload 방지 (user-data 중단 현상 우회)
sudo dnf config-manager --save --setopt=selinux=0 || true

# Docker 설치 (AL2023 패키지명: moby-*)
sudo dnf install -y docker || sudo dnf install -y moby-engine moby-cli

# Docker 실행 및 부팅연동 설정
sudo systemctl enable --now docker

# ec2-user docker 그룹 추가
sudo usermod -aG docker ec2-user

# AWS CLI 설치 (필요시)
if ! command -v aws &>/dev/null; then
  sudo dnf install -y awscli
fi

# ECR 로그인
aws ecr get-login-password --region ${aws_region} \
  | docker login --username AWS --password-stdin ${image_uri_registry}

# 기존 컨테이너 정리
docker stop ${service_name} 2>/dev/null || true
docker rm ${service_name} 2>/dev/null || true

# 최신 이미지 pull
docker pull ${image_uri_full}

# [중요] SSM Parameter Store에서 DB 비밀번호 조회 (KMS 복호화 포함)
DB_PASSWORD=$(aws ssm get-parameter \
  --name "${db_password_ssm_path}" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region ${aws_region})

# 컨테이너 실행
docker run -d \
  --name ${service_name} \
  --restart unless-stopped \
  -p ${app_port}:${container_port} \
  -e SERVICE_NAME="${service_name}" \
  -e REGION="${region_label}" \
  -e APP_ENV="${app_env}" \
  -e DB_HOST="${db_host}" \
  -e DB_PORT="${db_port}" \
  -e DB_NAME="${db_name}" \
  -e DB_USER="${db_user}" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e ALLOW_STRESS="${allow_stress}" \
  -e IDC_HOST="${idc_host}" \
  -e IDC_PORT="${idc_port}" \
  ${image_uri_full}

# CloudWatch Agent 설치/설정
sudo dnf install -y amazon-cloudwatch-agent
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
aws ssm get-parameter \
  --name "/prod/ddos/t1/seoul/cloudwatch/config" \
  --with-decryption \
  --region ${aws_region} \
  --query "Parameter.Value" \
  --output text \
  | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json >/dev/null

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl restart amazon-cloudwatch-agent
