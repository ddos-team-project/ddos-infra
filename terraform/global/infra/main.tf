###############################
# 1. Route53 Hosted Zone 조회
###############################
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

locals {
  fqdn         = "${var.subdomain}.${var.domain_name}"
  s3_origin_id = "S3-${local.fqdn}"
}

###############################
# 2. S3 버킷 (정적 웹 호스팅)
###############################
resource "aws_s3_bucket" "infra" {
  bucket = "dh-${var.environment}-${var.subdomain}"

  tags = merge(var.tags, {
    Name = "dh-${var.environment}-${var.subdomain}"
  })
}

resource "aws_s3_bucket_public_access_block" "infra" {
  bucket = aws_s3_bucket.infra.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "infra" {
  bucket = aws_s3_bucket.infra.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "infra" {
  bucket = aws_s3_bucket.infra.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

###############################
# 3. CloudFront OAC
###############################
resource "aws_cloudfront_origin_access_control" "infra" {
  name                              = "${var.subdomain}-oac"
  description                       = "OAC for ${var.subdomain} S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

###############################
# 4. S3 버킷 정책
###############################
resource "aws_s3_bucket_policy" "infra" {
  bucket = aws_s3_bucket.infra.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.infra.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.infra.arn
          }
        }
      }
    ]
  })
}

###############################
# 5. ACM 인증서 (us-east-1)
###############################
resource "aws_acm_certificate" "infra" {
  provider          = aws.us_east_1
  domain_name       = local.fqdn
  validation_method = "DNS"

  tags = merge(var.tags, {
    Name = "${var.subdomain}-cert"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.infra.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "infra" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.infra.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

###############################
# 6. CloudFront 배포
###############################
resource "aws_cloudfront_distribution" "infra" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [local.fqdn]
  comment             = "Infra Test Service"

  origin {
    domain_name              = aws_s3_bucket.infra.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.infra.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.infra.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(var.tags, {
    Name = "${var.subdomain}-cloudfront"
  })

  depends_on = [aws_acm_certificate_validation.infra]
}

###############################
# 7. Route53 레코드
###############################
resource "aws_route53_record" "infra" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.infra.domain_name
    zone_id                = aws_cloudfront_distribution.infra.hosted_zone_id
    evaluate_target_health = false
  }
}
