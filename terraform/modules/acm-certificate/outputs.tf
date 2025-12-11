output "certificate_arn" {
  description = "ACM 인증서 ARN"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "certificate_id" {
  description = "ACM 인증서 ID"
  value       = aws_acm_certificate.this.id
}

output "domain_name" {
  description = "인증서 도메인 이름"
  value       = aws_acm_certificate.this.domain_name
}
