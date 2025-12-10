data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# IAM role/policy for EC2 (ECR pull + CloudWatch logs)
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = var.tags
}

resource "aws_iam_policy" "ec2_policy" {
  name   = "${var.name}-ec2-policy"
  policy = data.aws_iam_policy_document.ec2_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# App SG (optional create)
resource "aws_security_group" "app" {
  count       = var.app_security_group_id == null ? 1 : 0
  name        = "${var.name}-app-sg"
  description = "Security group for App EC2"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-app-sg" })
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-v2-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 10
      volume_type = "gp3"
      encrypted   = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user-data.tpl", {
    aws_region         = var.aws_region
    image_uri_registry = split("/", var.image_uri)[0]
    image_uri_full     = var.image_uri
    app_port           = var.app_port
    container_port     = var.container_port
    service_name       = var.service_name
    region_label       = var.region_label
    app_env            = var.app_env
    db_host            = var.db_host
    db_port            = var.db_port
    db_name            = var.db_name
    db_user            = var.db_user
    db_password        = var.db_password
  }))

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_security_group_id != null ? var.app_security_group_id : aws_security_group.app[0].id]
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-ec2" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = "${var.name}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.app_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns = var.target_group_arns

  tag {
    key                 = "Name"
    value               = "${var.name}-ec2"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
