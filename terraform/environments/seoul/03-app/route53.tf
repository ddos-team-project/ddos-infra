data "aws_route53_zone" "root" {
  count        = var.route53_zone_name != null ? 1 : 0
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "healthcheck" {
  count   = var.route53_zone_name != null && var.route53_record_name != null ? 1 : 0
  zone_id = data.aws_route53_zone.root[0].zone_id
  name    = var.route53_record_name
  type    = "A"

  alias {
    name                   = module.healthcheck_api_alb.alb_dns_name
    zone_id                = module.healthcheck_api_alb.alb_zone_id
    evaluate_target_health = true
  }
}
