variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "dh"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "tier" {
  description = "Infrastructure tier (net, db, t1, t2)"
  type        = string
  default     = "net"
}

variable "region_code" {
  description = "Short region code (apne2, apne1)"
  type        = string
  default     = "apne2"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "devops"
}

variable "location" {
  description = "Location name (seoul, tokyo)"
  type        = string
  default     = "seoul"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "dh-prod-net-seoul-vpc"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks (App/EKS)"
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "database_subnets" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.10.20.0/24", "10.10.21.0/24"]
}

variable "intra_subnets" {
  description = "Intra subnet CIDR blocks (TGW, Endpoints)"
  type        = list(string)
  default     = ["10.10.30.0/24", "10.10.31.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway (false = one per AZ for HA)"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "tgw_description" {
  description = "Transit Gateway description"
  type        = string
  default     = "DH Prod Network TGW - Seoul"
}

variable "tgw_name" {
  description = "Transit Gateway name"
  type        = string
  default     = "dh-prod-net-seoul-tgw"
}

# IDC VPN 설정
variable "idc_public_ip" {
  description = "IDC 라즈베리파이 공인 IP"
  type        = string
  default     = "39.118.88.182"
}

variable "idc_cidr" {
  description = "IDC 내부 네트워크 CIDR"
  type        = string
  default     = "192.168.0.0/24"
}

variable "idc_host_cidr" {
  description = "IDC 라즈베리파이 호스트 CIDR"
  type        = string
  default     = "192.168.0.10/32"
}
