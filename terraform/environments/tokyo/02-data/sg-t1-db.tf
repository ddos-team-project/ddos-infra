resource "aws_security_group" "aurora_tokyo_t1" {
  name        = "dh-prod-t1-tokyo-sg-db"
  description = "Aurora DB security group for Tokyo Tier1"
  vpc_id      = data.terraform_remote_state.network_tokyo.outputs.vpc_id

  ## 인바운드
  # MySQL 3306 - 03-app 스택에서 SG rule로 추가 예정 (도쿄 App SG → DB SG)

  ## 아웃바운드
  # PoC 단계에서는 all-allow, 이후 필요에 맞게 좁혀서 수정
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name      = "dh-prod-t1-tokyo-sg-db"
    Project   = "dh"
    Env       = "prod"
    Region    = "apne1"
    ManagedBy = "terraform"
    Owner     = "devops"
    Tier      = "t1"
  }
}
