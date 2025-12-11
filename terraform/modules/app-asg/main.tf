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
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups"
    ]
    resources = ["*"]
  }

  # SSM Parameter Store에서 DB 비밀번호를 읽을 수 있도록 권한 추가
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = ["*"]
  }

  # SSM Parameter가 KMS로 암호화되어 있으므로 복호화 권한 필요
  statement {
    actions = [
      "kms:Decrypt"
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

# 앱 컨테이너 실행을 위한 user-data
data "template_file" "user_data" {
  template = file("${path.module}/user-data.tpl")
  vars = {
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
    allow_stress       = var.allow_stress_endpoint
    cwagent_ssm_name   = var.cwagent_ssm_name

    db_password_ssm_path = var.db_password_ssm_path

  }
}

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-v2-"
  image_id      = coalesce(var.ami_id, data.aws_ami.amazon_linux_2023[0].id)
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
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
    allow_stress       = var.allow_stress_endpoint

    idc_host             = var.idc_host
    idc_port             = var.idc_port
    cwagent_ssm_name     = var.cwagent_ssm_name
    db_password_ssm_path = var.db_password_ssm_path

  }))

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.app_sg_ids
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

  # Target groups are provided by the ALB module.
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

# 타깃 추적 기반 오토스케일(평균 CPU %)
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  count                     = var.enable_target_tracking ? 1 : 0
  name                      = "${var.name}-cpu-target-tracking"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  estimated_instance_warmup = var.estimated_instance_warmup

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = var.target_cpu_utilization
    disable_scale_in = false
  }
}
data "aws_ami" "amazon_linux_2023" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
