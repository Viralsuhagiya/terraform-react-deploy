
resource "aws_vpc" "react_app" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name =  "${var.app_name}-${var.env}-vpc"
  }
}

resource "aws_internet_gateway" "react_app" {
  vpc_id = aws_vpc.react_app.id
}

resource "aws_subnet" "react_app_subnet1" {
  vpc_id = "${aws_vpc.react_app.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "react_app_subnet2" {
  vpc_id     = aws_vpc.react_app.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}


resource "aws_route_table" "react_app" {
  vpc_id = aws_vpc.react_app.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.react_app.id
  }

  tags = {
    Name =  "${var.app_name}-${var.env}-route-table"
  }
}

resource "aws_route_table_association" "react_app_a" {
  subnet_id      = aws_subnet.react_app_subnet1.id
  route_table_id = aws_route_table.react_app.id
}

resource "aws_route_table_association" "react_app_b" {
  subnet_id      = aws_subnet.react_app_subnet2.id
  route_table_id = aws_route_table.react_app.id
}