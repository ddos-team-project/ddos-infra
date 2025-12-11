# ============================================================
# VPN Connection to IDC (Raspberry Pi)
# ============================================================
# IDC 라즈베리파이와 도쿄 TGW 간 Site-to-Site VPN 연결
# - Active-Active 구성 (Tunnel 2개)
# - Static Routing
# - TGW ECMP 지원으로 트래픽 분산
# ============================================================

# Customer Gateway (IDC 라즈베리파이)
resource "aws_customer_gateway" "idc" {
  bgp_asn    = 65000  # Private ASN (서울과 동일)
  ip_address = "39.118.88.182"  # 라즈베리파이 공인 IP (서울과 동일)
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
  transit_gateway_id  = aws_ec2_transit_gateway.tokyo_tgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  # VPN 터널 옵션 (서울과 다른 대역 사용)
  tunnel1_inside_cidr = "169.254.45.0/30"  # 서울과 겹치지 않게
  tunnel2_inside_cidr = "169.254.45.4/30"  # 서울과 겹치지 않게

  # DPD (Dead Peer Detection) 설정
  tunnel1_dpd_timeout_action = "restart"
  tunnel2_dpd_timeout_action = "restart"

  # 암호화 설정 (Phase 1 - IKE)
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]  # modp2048
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

# TGW Route Table 자동 전파
# TGW 설정의 default_route_table_propagation = "enable"로 인해
# VPN Connection 생성 시 자동으로 192.168.0.0/24 경로가 TGW Route Table에 추가됨
# 따라서 별도의 Static Route 리소스 불필요
