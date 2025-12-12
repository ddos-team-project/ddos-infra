# Allow MySQL from Tokyo App SG to DB SG (from 02-data state)
resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  description              = "Allow MySQL from Tokyo App Tier1"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"

  security_group_id        = data.terraform_remote_state.db.outputs.security_group_id
  source_security_group_id = aws_security_group.app_tokyo_t1.id
}
