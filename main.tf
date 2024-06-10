resource "aws_vpc" "jazira-webApp" {
  cidr_block = "10.0.0.0/16"


  tags = {
    Name = "jazira-webApp"
  }
}

resource "aws_internet_gateway" "jazira-webApp-igw" {
  vpc_id = aws_vpc.jazira-webApp.id

  tags = {
    Name = "jazira-webApp-igw"
  }
}

resource "aws_subnet" "jazira-webApp-public1-us-east-1a" {
  vpc_id            = aws_vpc.jazira-webApp.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability-zone-1a

  map_public_ip_on_launch = true

  tags = {
    Name = "jazira-webApp-public1-us-east-1a"
  }
}

resource "aws_subnet" "jazira-webApp-public2-us-east-1b" {
  vpc_id            = aws_vpc.jazira-webApp.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability-zone-1b
  map_public_ip_on_launch = true
  tags = {
    Name = "jazira-webApp-public2-us-east-1b"
  }
}

resource "aws_subnet" "jazira-webApp-private1-us-east-1a" {
  vpc_id            = aws_vpc.jazira-webApp.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.availability-zone-1a

  tags = {
    Name = "jazira-webApp-private1-us-east-1a"
  }
}

resource "aws_subnet" "jazira-webApp-private2-us-east-1b" {
  vpc_id            = aws_vpc.jazira-webApp.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.availability-zone-1b

  tags = {
    Name = "jazira-webApp-private2-us-east-1b"
  }
}

resource "aws_subnet" "jazira-webApp-private3-us-east-1a" {
  vpc_id            = aws_vpc.jazira-webApp.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = var.availability-zone-1a

  tags = {
    Name = "jazira-webApp-private3-us-east-1a"
  }
}

resource "aws_subnet" "jazira-webApp-private4-us-east-1b" {
  vpc_id            = aws_vpc.jazira-webApp.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = var.availability-zone-1b

  tags = {
    Name = "jazira-webApp-private4-us-east-1b"
  }
}

resource "aws_route_table" "jazira-webApp-web-tier-public-rt" {
  vpc_id = aws_vpc.jazira-webApp.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jazira-webApp-igw.id
  }

  tags = {
    Name = "jazira-webApp-web-tier-public-rt"
  }
}

resource "aws_route_table_association" "public-route-table-assoc-1a" {
  subnet_id      = aws_subnet.jazira-webApp-public1-us-east-1a.id
  route_table_id = aws_route_table.jazira-webApp-web-tier-public-rt.id
}

resource "aws_route_table_association" "public-route-table-assoc-1b" {
  subnet_id      = aws_subnet.jazira-webApp-public2-us-east-1b.id
  route_table_id = aws_route_table.jazira-webApp-web-tier-public-rt.id
}

resource "aws_route_table" "jazira-webApp-app-tier-private-rt" {
  vpc_id = aws_vpc.jazira-webApp.id

  tags = {
    Name = "jazira-webApp-app-tier-private-rt"
  }
}

resource "aws_route_table_association" "private-route-table-assoc-1a" {
  subnet_id      = aws_subnet.jazira-webApp-private1-us-east-1a.id
  route_table_id = aws_route_table.jazira-webApp-app-tier-private-rt.id
}

resource "aws_route_table_association" "private-route-table-assoc-1b" {
  subnet_id      = aws_subnet.jazira-webApp-private2-us-east-1b.id
  route_table_id = aws_route_table.jazira-webApp-app-tier-private-rt.id
}

resource "aws_eip" "jazira-eip" {

  tags = {
    Name = "jazira-eip"
  }
}

resource "aws_nat_gateway" "public-NAT-1" {
  allocation_id = aws_eip.jazira-eip.id
  subnet_id     = aws_subnet.jazira-webApp-public1-us-east-1a.id

  tags = {
    Name = "public-NAT-1"
  }
}