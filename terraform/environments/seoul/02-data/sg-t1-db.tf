resource "aws_security_group" "aurora_seoul_t1" {
  name        = "dh-prod-t1-seoul-sg-db"
  description = "Aurora DB security group for Seoul Tier1"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ## 인바운드
  # MySQL 3306 - 03-app 레이어에서 SG rule로 추가됨

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
    Name      = "ddh-prod-t1-seoul-sg-db"
    Project   = "dh"
    Env       = "prod"
    Region    = "apne2"
    ManagedBy = "terraform"
    Owner     = "devops"
    Tier      = "t1"
  }
}
