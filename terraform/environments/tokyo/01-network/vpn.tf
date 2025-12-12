# ============================================================
# VPN Connection to IDC (Raspberry Pi)
# ============================================================
# IDC ?¼ì¦ˆë² ë¦¬?Œì´?€ ?„ì¿„ TGW ê°?Site-to-Site VPN ?°ê²°
# - Active-Active êµ¬ì„± (Tunnel 2ê°?
# - Static Routing
# - TGW ECMP ì§€?ìœ¼ë¡??¸ë˜??ë¶„ì‚°
# ============================================================

# Customer Gateway (IDC ?¼ì¦ˆë² ë¦¬?Œì´)
resource "aws_customer_gateway" "idc" {
  bgp_asn    = 65000  # Private ASN (?œìš¸ê³??™ì¼)
  ip_address = "39.118.88.182"  # ?¼ì¦ˆë² ë¦¬?Œì´ ê³µì¸ IP (?œìš¸ê³??™ì¼)
  type       = "ipsec.1"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cgw-idc"
    }
  )
}

# VPN Connection (TGW???°ê²°)
resource "aws_vpn_connection" "idc" {
  customer_gateway_id = aws_customer_gateway.idc.id
  transit_gateway_id  = aws_ec2_transit_gateway.tokyo_tgw.id
  type                = "ipsec.1"
  static_routes_only  = true

  # VPN ?°ë„ ?µì…˜ (?œìš¸ê³??¤ë¥¸ ?€???¬ìš©)
  tunnel1_inside_cidr = "169.254.45.0/30"  # ?œìš¸ê³?ê²¹ì¹˜ì§€ ?Šê²Œ
  tunnel2_inside_cidr = "169.254.45.4/30"  # ?œìš¸ê³?ê²¹ì¹˜ì§€ ?Šê²Œ

  # DPD (Dead Peer Detection) ?¤ì •
  tunnel1_dpd_timeout_action = "restart"
  tunnel2_dpd_timeout_action = "restart"

  # ?”í˜¸???¤ì • (Phase 1 - IKE)
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]  # modp2048
  tunnel1_ike_versions                 = ["ikev2"]

  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_ike_versions                 = ["ikev2"]

  # ?”í˜¸???¤ì • (Phase 2 - ESP)
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
  destination_cidr_block         = "192.168.0.10/32"
  transit_gateway_route_table_id = aws_ec2_transit_gateway.tokyo_tgw.association_default_route_table_id
  transit_gateway_attachment_id  = aws_vpn_connection.idc.transit_gateway_attachment_id
}
# TGW Route Table ?ë™ ?„íŒŒ
# TGW ?¤ì •??default_route_table_propagation = "enable"ë¡??¸í•´
# VPN Connection ?ì„± ???ë™?¼ë¡œ 192.168.0.0/24 ê²½ë¡œê°€ TGW Route Table??ì¶”ê???
# ?°ë¼??ë³„ë„??Static Route ë¦¬ì†Œ??ë¶ˆí•„??

