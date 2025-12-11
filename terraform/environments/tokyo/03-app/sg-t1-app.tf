resource "aws_security_group" "app_tokyo_t1" {
  name        = "dh-prod-t1-tokyo-sg-app"
  description = "App EC2 security group for Tokyo Tier1"
  vpc_id      = local.vpc_id

  # App Port 8080 from ALB SG only
  ingress {
    description = "Allow app traffic from ALB only"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"

    security_groups = [aws_security_group.alb_tokyo_t1.id]
  }

  # allow all egress (DB/HTTPS/etc)
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
    Region    = "apne1"
    ManagedBy = "terraform"
    Owner     = "devops"
    Tier      = "t1"
  }
}
