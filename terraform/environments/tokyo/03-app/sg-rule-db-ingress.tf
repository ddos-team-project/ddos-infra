# Allow MySQL from Tokyo App SG into the Tokyo Aurora SG
resource "aws_security_group_rule" "db_from_app" {
  type        = "ingress"
  description = "Allow MySQL from Tokyo App Tier1"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"

  # Aurora SG from 02-data
  security_group_id = data.terraform_remote_state.db.outputs.security_group_id

  # App SG from this stack
  source_security_group_id = aws_security_group.app_tokyo_t1.id
}
