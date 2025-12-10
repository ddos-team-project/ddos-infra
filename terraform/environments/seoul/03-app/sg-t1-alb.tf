resource "aws_security_group" "alb_seoul_t1" {
  name        = "dh-prod-t1-seoul-sg-alb"
  description = "ALB security group for Seoul Tier1 non-core services"
  vpc_id      = local.vpc_id

  tags = {
    Name      = "dh-prod-t1-seoul-sg-alb"
    Project   = "dh"
    Env       = "prod"
    Region    = "apne2"
    ManagedBy = "terraform"
    Owner     = "devops"
    Tier      = "t1"
  }
}

## 인바운드 룰
# HTTP (80) from anywhere
resource "aws_security_group_rule" "alb_seoul_ingress_http" {
  type             = "ingress"
  description      = "Allow HTTP from internet"
  from_port        = 80
  to_port          = 80
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.alb_seoul_t1.id
}

# HTTPS (443) from anywhere
resource "aws_security_group_rule" "alb_seoul_ingress_https" {
  type             = "ingress"
  description      = "Allow HTTPS from internet"
  from_port        = 443
  to_port          = 443
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.alb_seoul_t1.id
}

## 아웃바운드 룰
# allow all (ALB → App, health check 등)
resource "aws_security_group_rule" "alb_seoul_egress_all" {
  type             = "egress"
  description      = "Allow all outbound traffic"
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.alb_seoul_t1.id
}
