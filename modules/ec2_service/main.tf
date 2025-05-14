data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  ami   = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.amazon_linux_2.value
  lc_id = "${var.name}-lt"
}

resource "aws_launch_template" "lt" {
  name_prefix            = local.lc_id
  image_id               = local.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.instance_sg_id]
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker
              systemctl start docker
              systemctl enable docker
              # Allow time for docker to start
              sleep 30
              usermod -aG docker ec2-user
              docker run -d -p 80:80 nginx
              EOF
  )
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.name}-asg"
  vpc_zone_identifier = var.public_subnet_ids
  max_size            = var.max_size
  min_size            = var.min_size
  desired_capacity    = var.min_size
  health_check_type   = "ELB"
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.name}-instance"
    propagate_at_launch = true
  }
}

resource "aws_lb" "alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_autoscaling_attachment" "asg_to_tg" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}

### Scaling policy: add 1 instance when ALB requests/inst > 100
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.alb.arn_suffix}/${aws_lb_target_group.tg.arn_suffix}"
    }
    target_value = 100
  }
}
