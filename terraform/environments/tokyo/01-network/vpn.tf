# ============================================================
# VPN Connection to IDC (Raspberry Pi)
# ============================================================
# IDC ?�즈베리?�이?� ?�쿄 TGW �?Site-to-Site VPN ?�결
# - Active-Active 구성 (Tunnel 2�?
# - Static Routing
# - TGW ECMP 지?�으�??�래??분산
# ============================================================

# Customer Gateway (IDC ?�즈베리?�이)
resource "aws_customer_gateway" "idc" {
  bgp_asn    = 65000  # Private ASN (?�울�??�일)
  ip_address = var.idc_public_ip
  type       = "ipsec.1"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cgw-idc"
    }
  )
}

# VPN Connection (TGW???�결)
resource "aws_vpn_connection" "idc" {
  customer_gateway_id = aws_customer_gateway.idc.id
  transit_gateway_id  = aws_ec2_transit_gateway.tokyo_tgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  # VPN ?�널 ?�션 (?�울�??�른 ?�???�용)
  tunnel1_inside_cidr = "169.254.45.0/30"  # ?�울�?겹치지 ?�게
  tunnel2_inside_cidr = "169.254.45.4/30"  # ?�울�?겹치지 ?�게

  # DPD (Dead Peer Detection) ?�정
  tunnel1_dpd_timeout_action = "restart"
  tunnel2_dpd_timeout_action = "restart"

  # ?�호???�정 (Phase 1 - IKE)
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]  # modp2048
  tunnel1_ike_versions                 = ["ikev2"]

  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_ike_versions                 = ["ikev2"]

  # ?�호???�정 (Phase 2 - ESP)
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]

  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-vpn-idc"
    }
  )
}

# TGW Route Table: 192.168.0.0/24 -> IDC(VPN) Attachment
resource "aws_ec2_transit_gateway_route" "idc_192_168_0_0_24" {
  destination_cidr_block         = var.idc_host_cidr
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tokyo_tgw.association_default_route_table_id
  transit_gateway_attachment_id  = aws_vpn_connection.idc.transit_gateway_attachment_id
}
# TGW Route Table ?�동 ?�파
# TGW ?�정??default_route_table_propagation = "enable"�??�해
# VPN Connection ?�성 ???�동?�로 192.168.0.0/24 경로가 TGW Route Table??추�???
# ?�라??별도??Static Route 리소??불필??

