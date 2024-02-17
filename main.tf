# 모듈화는 추후 진행
provider "aws" {
  region  = "ap-northeast-2"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "public-subnet-a"
  }
}


resource "aws_subnet" "public_subnet_c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "public-subnet-c"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet-gateway"
  }
}


resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "route_table_association_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "route_table_association_c" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.route_table.id
}


resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"

  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "private-subnet-c"
  }
}

resource "aws_eip" "nat_a" {
  vpc   = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "nat_c" {
  vpc   = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "nat_gateway_a" {
  allocation_id = aws_eip.nat_a.id

  subnet_id = aws_subnet.private_subnet_a.id

  tags = {
    Name = "nat-gateway-a"
  }
}

resource "aws_nat_gateway" "nat_gateway_c" {
  allocation_id = aws_eip.nat_c.id

  subnet_id = aws_subnet.private_subnet_c.id

  tags = {
    Name = "nat-gateway-c"
  }
}



