resource "aws_route53_zone" "main" {
  name    = "ddos.io.kr"
  comment = "Hosted Zone for ddos.io.kr"
}

output "name_servers" {
  value = aws_route53_zone.main.name_servers
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "admin-role"
}
