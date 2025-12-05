# resource "aws_security_group" "db" {
#   name        = "${var.name}-db-sg"
#   description = "SG for ${var.name} Aurora"
#   vpc_id      = var.vpc_id

#   dynamic "ingress" {
#     for_each = var.app_sg_ids
#     content {
#       from_port       = 3306
#       to_port         = 3306
#       protocol        = "tcp"
#       security_groups = [ingress.value]
#       description     = "MySQL access from app SG"
#     }
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = merge(var.tags, { Name = "${var.name}-db-sg" })
# }

# resource "aws_db_subnet_group" "this" {
#   name       = "${var.name}-subnet-group"
#   subnet_ids = var.db_subnet_ids

#   tags = merge(var.tags, { Name = "${var.name}-db-subnet-group" })
# }

# resource "aws_rds_cluster" "this" {
#   cluster_identifier = "${var.name}-cluster"

#   engine         = "aurora-mysql"
#   engine_version = var.engine_version

#   master_username = var.master_username
#   master_password = var.master_password

#   db_subnet_group_name   = aws_db_subnet_group.this.name
#   vpc_security_group_ids = [aws_security_group.db.id]

#   backup_retention_period = var.backup_retention_days
#   preferred_backup_window = var.preferred_backup_window

#   storage_encrypted   = true
#   deletion_protection = true

#   tags = merge(var.tags, { Name = "${var.name}-cluster" })
# }

# resource "aws_rds_cluster_instance" "writer" {
#   identifier         = "${var.name}-writer"
#   cluster_identifier = aws_rds_cluster.this.id
#   instance_class     = var.instance_class
#   engine             = aws_rds_cluster.this.engine
#   engine_version     = aws_rds_cluster.this.engine_version

#   publicly_accessible = false

#   tags = merge(var.tags, { Name = "${var.name}-writer", Role = "writer" })
# }

# resource "aws_rds_cluster_instance" "reader" {
#   identifier         = "${var.name}-reader"
#   cluster_identifier = aws_rds_cluster.this.id
#   instance_class     = var.instance_class
#   engine             = aws_rds_cluster.this.engine
#   engine_version     = aws_rds_cluster.this.engine_version

#   publicly_accessible = false

#   tags = merge(var.tags, { Name = "${var.name}-reader", Role = "reader" })
# }
# resource "aws_rds_global_cluster" "this" {
#   count                     = var.is_primary ? 1 : 0
#   global_cluster_identifier = "${var.name}-global"
#   engine                    = "aurora-mysql"
#   engine_version            = var.engine_version
# }
##############################################
# DB Security Group
##############################################
resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "SG for ${var.name} Aurora"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.app_sg_ids
    content {
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [ingress.value]
      description     = "MySQL access from app SG"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-db-sg" })
}

##############################################
# DB Subnet Group
##############################################
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = merge(var.tags, { Name = "${var.name}-db-subnet-group" })
}

##############################################
# Aurora Global Cluster (Primary 지역에서만 생성)
##############################################
resource "aws_rds_global_cluster" "this" {
  count                     = var.is_primary ? 1 : 0
  global_cluster_identifier = "${var.name}-global"
  engine                    = "aurora-mysql"
  engine_version            = var.engine_version
}

##############################################
# Aurora Cluster
##############################################
resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.name}-cluster"

  engine         = "aurora-mysql"
  engine_version = var.engine_version

  master_username = var.master_username
  master_password = var.master_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # 글로벌 클러스터 조인 (Secondary 지역일 때만)
  global_cluster_identifier = var.is_primary ? null : var.global_cluster_identifier

  storage_encrypted   = true
  deletion_protection = false

  backup_retention_period = var.backup_retention_days
  preferred_backup_window = var.preferred_backup_window

  tags = merge(var.tags, { Name = "${var.name}-cluster" })
}

##############################################
# Writer / Reader Instances
##############################################
resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.name}-writer"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  publicly_accessible = false

  tags = merge(var.tags, { Name = "${var.name}-writer", Role = "writer" })
}

resource "aws_rds_cluster_instance" "reader" {
  identifier         = "${var.name}-reader"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  publicly_accessible = false

  tags = merge(var.tags, { Name = "${var.name}-reader", Role = "reader" })
}
