# ============================================================
# VPN Connection to IDC (Raspberry Pi)
# ============================================================
# IDC 라즈베리파이와 서울 TGW 간 Site-to-Site VPN 연결
# - Active-Active 구성 (Tunnel 2개)
# - Static Routing
# - TGW ECMP 지원으로 트래픽 분산
# ============================================================

# Customer Gateway (IDC 라즈베리파이)
resource "aws_customer_gateway" "idc" {
  bgp_asn    = 65000 # Private ASN
  ip_address = var.idc_public_ip
  type       = "ipsec.1"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cgw-idc"
    }
  )
}

# VPN Connection (TGW에 연결)
resource "aws_vpn_connection" "idc" {
  customer_gateway_id = aws_customer_gateway.idc.id
  transit_gateway_id  = aws_ec2_transit_gateway.seoul_tgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  # VPN 터널 옵션 (보안 강화)
  tunnel1_inside_cidr = "169.254.44.0/30" # AWS 자동 할당 가능
  tunnel2_inside_cidr = "169.254.44.4/30" # AWS 자동 할당 가능

  # DPD (Dead Peer Detection) 설정
  tunnel1_dpd_timeout_action = "restart"
  tunnel2_dpd_timeout_action = "restart"

  # 암호화 설정 (Phase 1 - IKE)
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14] # modp2048
  tunnel1_ike_versions                 = ["ikev2"]

  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_ike_versions                 = ["ikev2"]

  # 암호화 설정 (Phase 2 - ESP)
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

  destination_cidr_block = var.idc_host_cidr

  transit_gateway_route_table_id = aws_ec2_transit_gateway.seoul_tgw.association_default_route_table_id
  transit_gateway_attachment_id  = aws_vpn_connection.idc.transit_gateway_attachment_id
}

# 참고: TGW default_route_table_propagation = "enable"이라도, static VPN 경로를 확실히 보장하려고 명시적으로 추가
