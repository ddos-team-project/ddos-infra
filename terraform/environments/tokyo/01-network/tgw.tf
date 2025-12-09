# Transit Gateway (리전 간 연결 및 IDC 연동 허브)
resource "aws_ec2_transit_gateway" "tokyo_tgw" {
  description                     = var.tgw_description
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = "enable"
  vpn_ecmp_support               = "enable"

  tags = merge(
    local.common_tags,
    {
      Name = var.tgw_name
    }
  )
}

# TGW와 VPC 연결 (Attachment)
resource "aws_ec2_transit_gateway_vpc_attachment" "tokyo_tgw_att" {
  subnet_ids         = module.vpc.intra_subnets
  transit_gateway_id = aws_ec2_transit_gateway.tokyo_tgw.id
  vpc_id             = module.vpc.vpc_id

  dns_support  = "enable"
  ipv6_support = "disable"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.tgw_name}-attachment"
    }
  )
}
