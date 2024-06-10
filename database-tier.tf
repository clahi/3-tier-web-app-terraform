resource "aws_security_group" "jazira-db-sg" {
  name        = "jazira-db-sg"
  description = "Allow access from the app tier"
  vpc_id      = aws_vpc.jazira-webApp.id

  tags = {
    Name = "jazira-db-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "jazira-db-sg" {
  security_group_id = aws_security_group.jazira-db-sg.id
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.jazira-appServer-sg.id
}

resource "aws_vpc_security_group_egress_rule" "jazira-db-sg" {
  security_group_id = aws_security_group.jazira-db-sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_db_subnet_group" "jazira-db-subnetGroup" {
  name       = "jazira-db-subnet-group"
  subnet_ids = [aws_subnet.jazira-webApp-private3-us-east-1a.id, aws_subnet.jazira-webApp-private4-us-east-1b.id]

  tags = {
    Name = "jazira-db-subnetGroup"
  }
}

resource "aws_db_instance" "jazira--webApp-db" {
  allocated_storage      = 10
  db_name                = "jaziraWebAppDb"
  identifier             = "jazira-web-app-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "Amran"
  password               = "Amran143"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.jazira-db-subnetGroup.name
  vpc_security_group_ids = [aws_security_group.jazira-db-sg.id]
}