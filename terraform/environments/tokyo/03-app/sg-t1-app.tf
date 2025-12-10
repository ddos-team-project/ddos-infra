resource "aws_security_group" "app_tokyo_t1" {
  name        = "dh-prod-t1-tokyo-sg-app"
  description = "App EC2 security group (tokyo Tier1)"
  vpc_id      = module.vpc.vpc_id

  ## 인바운드
  # HTTPS 443 from ALB SG만 허용
  ingress {
    description = "Allow HTTP from ALB only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    #=도쿄 alb-t1에서 오는 요청만 처리
    security_groups = [aws_security_group.alb_tokyo.id]
  }

  ## 아웃바운드
  # 전체 허용 (추후 필요시 3306/80/443 으로 좁히기)
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name      = "dh-prod-t1-tokyo-sg-app"
    Project   = "dh"
    Env       = "prod"
    Region    = "apne2"
    ManagedBy = "terraform"
    Owner     = "devops"
    Tier      = "t1"
  }
}
