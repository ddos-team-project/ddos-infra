# 02-data 레이어의 DB SG에 인바운드 룰 추가
# App SG에서만 MySQL(3306) 접근 허용

resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  description              = "서울 App Tier1에서 MySQL 접근 허용"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"

  # 02-data 레이어의 DB SG
  security_group_id        = data.terraform_remote_state.db.outputs.db_sg_id

  # 03-app 레이어의 App SG
  source_security_group_id = aws_security_group.app_seoul_t1.id
}
