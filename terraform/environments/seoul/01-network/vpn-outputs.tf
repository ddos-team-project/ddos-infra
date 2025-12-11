# ============================================================
# VPN Outputs (strongSwan 설정에 필요한 정보)
# ============================================================

# Customer Gateway ID
output "seoul_customer_gateway_id" {
  description = "서울 Customer Gateway ID"
  value       = aws_customer_gateway.idc.id
}

# VPN Connection ID
output "seoul_vpn_connection_id" {
  description = "서울 VPN Connection ID"
  value       = aws_vpn_connection.idc.id
}

# Tunnel 1 정보
output "seoul_tunnel1_address" {
  description = "서울 Tunnel 1 Outside IP (AWS 측 엔드포인트)"
  value       = aws_vpn_connection.idc.tunnel1_address
}

output "seoul_tunnel1_cgw_inside_address" {
  description = "서울 Tunnel 1 Inside IP (IDC 측)"
  value       = aws_vpn_connection.idc.tunnel1_cgw_inside_address
}

output "seoul_tunnel1_vgw_inside_address" {
  description = "서울 Tunnel 1 Inside IP (AWS 측)"
  value       = aws_vpn_connection.idc.tunnel1_vgw_inside_address
}

output "seoul_tunnel1_preshared_key" {
  description = "서울 Tunnel 1 Pre-Shared Key (PSK)"
  value       = aws_vpn_connection.idc.tunnel1_preshared_key
  sensitive   = true
}

# Tunnel 2 정보
output "seoul_tunnel2_address" {
  description = "서울 Tunnel 2 Outside IP (AWS 측 엔드포인트)"
  value       = aws_vpn_connection.idc.tunnel2_address
}

output "seoul_tunnel2_cgw_inside_address" {
  description = "서울 Tunnel 2 Inside IP (IDC 측)"
  value       = aws_vpn_connection.idc.tunnel2_cgw_inside_address
}

output "seoul_tunnel2_vgw_inside_address" {
  description = "서울 Tunnel 2 Inside IP (AWS 측)"
  value       = aws_vpn_connection.idc.tunnel2_vgw_inside_address
}

output "seoul_tunnel2_preshared_key" {
  description = "서울 Tunnel 2 Pre-Shared Key (PSK)"
  value       = aws_vpn_connection.idc.tunnel2_preshared_key
  sensitive   = true
}
