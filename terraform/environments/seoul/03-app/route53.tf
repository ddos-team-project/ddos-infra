data "aws_route53_zone" "root" {
  count        = var.route53_zone_name != null ? 1 : 0
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "tier1" {

  count          = var.enable_route53_tier1_record ? 1 : 0
  zone_id        = data.aws_route53_zone.root[0].zone_id
  name           = var.route53_tier1_record
  type           = "A"
  set_identifier = "seoul"

  weighted_routing_policy {
    weight = 80 # 서울 트래픽 비율 (80:20 중 80)
  }


  alias {
    name                   = module.healthcheck_api_alb.alb_dns_name
    zone_id                = module.healthcheck_api_alb.alb_zone_id
    evaluate_target_health = true
  }
}
