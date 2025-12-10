resource "aws_security_group" "aurora_tokyo_t1" {
  name        = "dh-prod-tokyo-sg-db-t1"
  description = "Aurora DB security group (tokyo Tier1)"
  vpc_id      = module.vpc.vpc_id

  ## 인바운드
  # MySQL 3306 from tokyo App SG
  ingress {
    description = "Allow MySQL from tokyo App Tier1"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"

    # 같은 VPC 안의 App SG에서만 접근 허용
    security_groups = [aws_security_group.app_tokyo_t1.id]
  }

  ## 아웃바운드
  # PoC 단계에서는 DB egress를 단순 all-allow로 두고, 추후 필요 시 별도 룰로 제한
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name      = "dh-prod-tokyo-sg-db-t1"
    Project   = "dh"
    Env       = "prod"
    Region    = "apne2"
    ManagedBy = "terraform"
    Owner     = "devops"
    Tier      = "t1"
  }
}
