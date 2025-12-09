# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = var.availability_zones

  # 서브넷 설계
  public_subnets   = var.public_subnets    # L1: Public (ALB, NAT)
  private_subnets  = var.private_subnets   # L3: Service (App - EKS)
  database_subnets = var.database_subnets  # L2: Base (DB)
  intra_subnets    = var.intra_subnets     # Infra (TGW, Endpoint)

  # NAT Gateway 설정
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway # 고가용성을 위해 AZ별 생성

  # VPN Gateway 설정
  enable_vpn_gateway = var.enable_vpn_gateway

  # DNS 설정
  enable_dns_hostnames = true
  enable_dns_support   = true

  # 서브넷별 태그 (EKS 등을 위한 자동 검색)
  public_subnet_tags = {
    Type = "Public"
  }

  private_subnet_tags = {
    Type = "Private-App"
  }

  database_subnet_tags = {
    Type = "Private-DB"
  }

  intra_subnet_tags = {
    Type = "Private-Infra"
  }

  tags = local.common_tags
}