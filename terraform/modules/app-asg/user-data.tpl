#!/bin/bash
set -xe

# SELinux kernel reload 방지 (user-data 중단 현상 해결)
sudo dnf config-manager --save --setopt=selinux=0 || true

# Docker 설치 (AL2023 패키지명은 moby-*)
sudo dnf install -y docker || sudo dnf install -y moby-engine moby-cli

# Docker 실행 및 부팅 시 자동 시작
sudo systemctl enable --now docker

# ec2-user docker 그룹 추가
sudo usermod -aG docker ec2-user


# AWS CLI 설치 (필요하면)
if ! command -v aws &>/dev/null; then
  sudo dnf install -y awscli
fi

# ECR 로그인
aws ecr get-login-password --region ${aws_region} \
  | docker login --username AWS --password-stdin ${image_uri_registry}

# 기존 컨테이너 제거
docker stop ${service_name} 2>/dev/null || true
docker rm ${service_name} 2>/dev/null || true

# 최신 이미지 pull
docker pull ${image_uri_full}

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
  -e DB_PASSWORD="${db_password}" \
  ${image_uri_full}
