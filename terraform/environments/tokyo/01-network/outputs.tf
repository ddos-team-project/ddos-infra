output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs (App/EKS)"
  value       = module.vpc.private_subnets
}

output "app_subnets" {
  description = "Application subnet IDs (alias for private_subnets)"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnets
}

output "db_subnets" {
  description = "Database subnet IDs (alias for database_subnets)"
  value       = module.vpc.database_subnets
}

output "intra_subnets" {
  description = "Intra subnet IDs (TGW, Endpoints)"
  value       = module.vpc.intra_subnets
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = module.vpc.natgw_ids
}

output "tgw_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.tokyo_tgw.id
}

output "tgw_attachment_id" {
  description = "Transit Gateway VPC Attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.tokyo_tgw_att.id
}
