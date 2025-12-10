###############################################
# EC2 + ALB + AutoScaling Group 모듈
# - Healthcheck API 컨테이너를 자동 실행하는 App 계층
# - ALB 헬스체크 기반 트래픽 배분 + ASG 확장
# - User-data 내부에서 docker pull / docker run 실행
###############################################


#############################################################
# Amazon Linux 2023 AMI (App EC2 용)
#############################################################
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ==== IAM 역할 (EC2가 ECR Pull / CloudWatch 로그를 사용할 수 있도록) ====

resource "aws_iam_role" "ec2_role" {
  name               = "${var.name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = var.tags
}

# EC2가 IAM Role을 사용할 수 있도록 Assume Role 정책
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# EC2가 컨테이너 이미지를 ECR에서 가져가고 로그를 CloudWatch에 남길 수 있도록 권한 설정
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

resource "aws_iam_policy" "ec2_policy" {
  name   = "${var.name}-ec2-policy"
  policy = data.aws_iam_policy_document.ec2_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# EC2에 IAM Role을 부여하기 위한 Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}


# ==== Security Group ====

# ALB → EC2 트래픽 전달을 위한 ALB SG
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for ALB ${var.name}"
  vpc_id      = var.vpc_id

  # 외부 트래픽 80 포트 허용
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 아웃바운드 전체 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

# EC2용 App SG (ALB만 접근 가능하도록)
resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "Security group for App EC2"
  vpc_id      = var.vpc_id

  # 외부에서 직접 접근 불가하고, ALB만 인바운드 허용
  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # 아웃바운드는 DB 및 인터넷 업데이트 용도로 전체 허용 (NAT 필수)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-app-sg" })
}


# ==== ALB (외부에서 App 계층 진입점) ====

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false # 인터넷 공개형
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.alb_subnet_ids # 반드시 public subnet

  tags = merge(var.tags, { Name = "${var.name}-alb" })
}

# ALB → EC2 트래픽 배분용 Target Group (HTTP 8080)
resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  # EC2 컨테이너 내부 /health 체크 결과 기반 상태 판별
  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.tags, { Name = "${var.name}-tg" })
}

# HTTP Listener (80 포트 → Target Group 전달)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}




# User-data 템플릿에 변수 주입
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
    db_password        = var.db_password
  }
}

# Launch Template (EC2 부팅 시 user_data 실행)
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

  # 컨테이너 실행 스크립트
  user_data = base64encode(data.template_file.user_data.rendered)

  # App은 private subnet + no public IP
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }

  # 태그
  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-ec2" })
  }

  lifecycle {
    create_before_destroy = true
  }
}


# ==== Auto Scaling Group ====

resource "aws_autoscaling_group" "this" {
  name                      = "${var.name}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.app_subnet_ids # private subnet
  health_check_type         = "ELB"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.this.arn]

  # 태그 (EC2 생성 시 자동 적용)
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

