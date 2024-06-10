resource "aws_security_group" "jazira-appServer-sg" {
  name        = "jazira-appServer-sg"
  description = "Allow ICMP-IPv4 jazira webServer security group"
  vpc_id      = aws_vpc.jazira-webApp.id

  tags = {
    Name = "jazira-appServer-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow-egress-to-internet" {
  security_group_id = aws_security_group.jazira-appServer-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow-ICMP-IPv4" {
  security_group_id            = aws_security_group.jazira-appServer-sg.id
  referenced_security_group_id = aws_security_group.allow-http.id
  ip_protocol                  = "icmp"
  from_port                    = 8
  to_port                      = 0
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh-from-bastionHost" {
  security_group_id            = aws_security_group.jazira-appServer-sg.id
  referenced_security_group_id = aws_security_group.jazira-bastionHost-sg.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow-access-from-database" {
  security_group_id = aws_security_group.jazira-appServer-sg.id
  referenced_security_group_id = aws_security_group.jazira-db-sg.id
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
}

resource "aws_launch_template" "jazira-appServer-template" {
  name                   = "jazira-appServer-template"
  image_id               = data.aws_ami.amazon-linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.jazira-appServer-sg.id]
  key_name               = aws_key_pair.demo-key.key_name

  user_data = filebase64("scripts/app_data.sh")
}

resource "aws_autoscaling_group" "jazira-appServer-asg" {
  name                = "jazira-appServer-asg"
  vpc_zone_identifier = [aws_subnet.jazira-webApp-private1-us-east-1a.id, aws_subnet.jazira-webApp-private2-us-east-1b.id]
  max_size            = 5
  min_size            = 2
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.jazira-appServer-template.id
    version = "$Latest"
  }
}

resource "aws_lb" "jazira-appServer-lb" {
  name               = "jazira-appServer-lb"
  security_groups    = [aws_security_group.jazira-appServer-sg.id]
  subnets            = [aws_subnet.jazira-webApp-private1-us-east-1a.id, aws_subnet.jazira-webApp-private2-us-east-1b.id]
  load_balancer_type = "application"
  internal           = true
}

resource "aws_lb_target_group" "jazira-appServer-tg" {
  name     = "jazira-appServer-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.jazira-webApp.id
}

resource "aws_lb_listener" "jazira-appServer-lb-listener" {
  load_balancer_arn = aws_lb.jazira-appServer-lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jazira-appServer-tg.arn
  }
}

resource "aws_autoscaling_attachment" "jazira-appServer-asg-tg-attachment" {
  autoscaling_group_name = aws_autoscaling_group.jazira-appServer-asg.id
  lb_target_group_arn    = aws_lb_target_group.jazira-appServer-tg.arn
}
