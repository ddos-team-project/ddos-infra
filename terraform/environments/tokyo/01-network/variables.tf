variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-northeast-1"
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
  default     = "apne1"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "devops"
}

variable "location" {
  description = "Location name (seoul, tokyo)"
  type        = string
  default     = "tokyo"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "dh-prod-net-tokyo-vpc"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks (App/EKS)"
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "database_subnets" {
  description = "Database subnet CIDR blocks"
  type        = list(string)
  default     = ["10.20.20.0/24", "10.20.21.0/24"]
}

variable "intra_subnets" {
  description = "Intra subnet CIDR blocks (TGW, Endpoints)"
  type        = list(string)
  default     = ["10.20.30.0/24", "10.20.31.0/24"]
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
  default     = "DH Prod Network TGW - Tokyo"
}

variable "tgw_name" {
  description = "Transit Gateway name"
  type        = string
  default     = "dh-prod-net-tokyo-tgw"
}
