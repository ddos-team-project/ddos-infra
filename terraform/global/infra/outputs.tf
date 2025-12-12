output "s3_bucket_name" {
  description = "S3 버킷 이름"
  value       = aws_s3_bucket.infra.id
}

output "s3_bucket_arn" {
  description = "S3 버킷 ARN"
  value       = aws_s3_bucket.infra.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront 배포 ID"
  value       = aws_cloudfront_distribution.infra.id
}

output "cloudfront_domain_name" {
  description = "CloudFront 도메인"
  value       = aws_cloudfront_distribution.infra.domain_name
}

output "url" {
  description = "서비스 URL"
  value       = "https://${local.fqdn}"
}
