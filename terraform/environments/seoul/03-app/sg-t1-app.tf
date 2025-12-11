resource "aws_security_group" "app_seoul_t1" {
  name        = "dh-prod-t1-seoul-sg-app"
  description = "App EC2 security group for Seoul Tier1"
  vpc_id      = local.vpc_id

  ## 인바운드
  # App Port 8080 from ALB SG만 허용
  ingress {
    description = "Allow app traffic from ALB only"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"

    #서울 alb-t1에서 오는 요청만 처리
    security_groups = [aws_security_group.alb_seoul_t1.id]
  }

  # ✅ IDC(192.168.0.0/24)에서 오는 ICMP(Ping) 허용
  ingress {
    description = "Allow ICMP from IDC VPN"
    from_port   = -1 # 모든 ICMP
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["192.168.0.10/32"]
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
    Name      = "dh-prod-t1-seoul-sg-app"
    Project   = "dh"
    Env       = "prod"
    Region    = "apne2"
    ManagedBy = "terraform"
    Owner     = "devops"
    Tier      = "t1"
  }
}
