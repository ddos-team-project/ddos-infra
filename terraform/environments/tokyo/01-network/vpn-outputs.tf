# ============================================================
# VPN Outputs (strongSwan 설정에 필요한 정보)
# ============================================================

# Customer Gateway ID
output "tokyo_customer_gateway_id" {
  description = "도쿄 Customer Gateway ID"
  value       = aws_customer_gateway.idc.id
}

# VPN Connection ID
output "tokyo_vpn_connection_id" {
  description = "도쿄 VPN Connection ID"
  value       = aws_vpn_connection.idc.id
}

# Tunnel 3 정보 (도쿄는 Tunnel 3, 4로 표시)
output "tokyo_tunnel3_address" {
  description = "도쿄 Tunnel 3 Outside IP (AWS 측 엔드포인트)"
  value       = aws_vpn_connection.idc.tunnel1_address
}

output "tokyo_tunnel3_cgw_inside_address" {
  description = "도쿄 Tunnel 3 Inside IP (IDC 측)"
  value       = aws_vpn_connection.idc.tunnel1_cgw_inside_address
}

output "tokyo_tunnel3_vgw_inside_address" {
  description = "도쿄 Tunnel 3 Inside IP (AWS 측)"
  value       = aws_vpn_connection.idc.tunnel1_vgw_inside_address
}

output "tokyo_tunnel3_preshared_key" {
  description = "도쿄 Tunnel 3 Pre-Shared Key (PSK)"
  value       = aws_vpn_connection.idc.tunnel1_preshared_key
  sensitive   = true
}

# Tunnel 4 정보
output "tokyo_tunnel4_address" {
  description = "도쿄 Tunnel 4 Outside IP (AWS 측 엔드포인트)"
  value       = aws_vpn_connection.idc.tunnel2_address
}

output "tokyo_tunnel4_cgw_inside_address" {
  description = "도쿄 Tunnel 4 Inside IP (IDC 측)"
  value       = aws_vpn_connection.idc.tunnel2_cgw_inside_address
}

output "tokyo_tunnel4_vgw_inside_address" {
  description = "도쿄 Tunnel 4 Inside IP (AWS 측)"
  value       = aws_vpn_connection.idc.tunnel2_vgw_inside_address
}

output "tokyo_tunnel4_preshared_key" {
  description = "도쿄 Tunnel 4 Pre-Shared Key (PSK)"
  value       = aws_vpn_connection.idc.tunnel2_preshared_key
  sensitive   = true
}
