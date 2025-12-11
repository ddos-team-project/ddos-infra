resource "aws_security_group" "alb_tokyo_t1" {
  name        = "dh-prod-t1-tokyo-sg-alb"
  description = "ALB security group for Tokyo Tier1 non-core services"
  vpc_id      = local.vpc_id

  tags = {
    Name      = "dh-prod-t1-tokyo-sg-alb"
    Project   = "dh"
    Env       = "prod"
    Region    = "apne1"
    ManagedBy = "terraform"
    Owner     = "devops"
    Tier      = "t1"
  }
}

# HTTP (80) from anywhere
resource "aws_security_group_rule" "alb_tokyo_ingress_http" {
  type             = "ingress"
  description      = "Allow HTTP from internet"
  from_port        = 80
  to_port          = 80
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.alb_tokyo_t1.id
}

# HTTPS (443) from anywhere
resource "aws_security_group_rule" "alb_tokyo_ingress_https" {
  type             = "ingress"
  description      = "Allow HTTPS from internet"
  from_port        = 443
  to_port          = 443
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.alb_tokyo_t1.id
}

# allow all egress
resource "aws_security_group_rule" "alb_tokyo_egress_all" {
  type             = "egress"
  description      = "Allow all outbound traffic"
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = aws_security_group.alb_tokyo_t1.id
}
