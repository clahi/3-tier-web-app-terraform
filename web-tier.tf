resource "aws_key_pair" "demo-key" {
  key_name   = "demo-key"
  public_key = file("${path.module}/demo-key.pub")
}

resource "aws_security_group" "allow-http" {
  name        = "allow-http"
  description = "Allow http from the internet"
  vpc_id      = aws_vpc.jazira-webApp.id

  tags = {
    Name = "allow-http"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow-http" {
  security_group_id = aws_security_group.allow-http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow-http" {
  security_group_id = aws_security_group.allow-http.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "allow-https" {
  security_group_id = aws_security_group.allow-http.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh" {
  security_group_id = aws_security_group.allow-http.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

data "aws_ami" "amazon-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_launch_template" "jazira-webServer-template" {
  name     = "jazira-webServer"
  image_id = data.aws_ami.amazon-linux.id

  vpc_security_group_ids = [aws_security_group.allow-http.id]

  instance_type = "t2.micro"

  key_name = aws_key_pair.demo-key.key_name



  user_data = filebase64("scripts/user_data.sh")
}

resource "aws_autoscaling_group" "jazira-webServer-asg" {
  name                = "jazira-webServer-asg"
  vpc_zone_identifier = [aws_subnet.jazira-webApp-public1-us-east-1a.id, aws_subnet.jazira-webApp-public2-us-east-1b.id]
  max_size            = 5
  min_size            = 2
  desired_capacity    = 2

  target_group_arns = [aws_lb_target_group.jazira-webServer-tg.arn]
  launch_template {
    id      = aws_launch_template.jazira-webServer-template.id
    version = "$Latest"
  }

}

resource "aws_lb" "jazira-webServer-alb" {
  name               = "jazira-webServer-alb"
  security_groups    = [aws_security_group.allow-http.id]
  subnets            = [aws_subnet.jazira-webApp-public1-us-east-1a.id, aws_subnet.jazira-webApp-public2-us-east-1b.id]
  load_balancer_type = "application"
}

resource "aws_lb_target_group" "jazira-webServer-tg" {
  name     = "jazira-webServer-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.jazira-webApp.id

}

resource "aws_lb_listener" "jazira-webServer-listener" {
  load_balancer_arn = aws_lb.jazira-webServer-alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jazira-webServer-tg.arn
  }
}

resource "aws_security_group" "jazira-bastionHost-sg" {
  name   = "jazira-bastionHost-sg"
  vpc_id = aws_vpc.jazira-webApp.id
}

resource "aws_vpc_security_group_egress_rule" "jazira-bastionHost-sg" {
  security_group_id = aws_security_group.jazira-bastionHost-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "jazira-bastionHost-sg" {
  security_group_id = aws_security_group.jazira-bastionHost-sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_instance" "jazira-bastionHost" {
  ami                    = data.aws_ami.amazon-linux.id
  vpc_security_group_ids = [aws_security_group.jazira-bastionHost-sg.id]
  key_name               = aws_key_pair.demo-key.key_name
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.jazira-webApp-public1-us-east-1a.id
}


