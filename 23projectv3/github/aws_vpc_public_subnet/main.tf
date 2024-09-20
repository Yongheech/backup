# VPC 생성
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames =  true
  enable_dns_support = true

  tags = { Name = "${var.instance_name}_vpc" }
}

# 서브넷 생성
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr
  availability_zone = var.avail_zone

  tags = { Name = "${var.instance_name}_subnet" }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = { Name = "${var.instance_name}_igw" }
}

# 라우팅 테이블 생성 및 인터넷 게이트웨이 연결
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name ="${var.instance_name}_public_rtb"}
}

# 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "public_rtbasso" {
  route_table_id = aws_route_table.public_rtb.id
  subnet_id = aws_subnet.public_subnet.id
}

# 보안그룹 생성
resource "aws_security_group" "public_sg" {
  name = "${var.instance_name}_public_sg"
  vpc_id = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.inbound_ports # 반복요소명 지정
    content {                    # 반복할 내용 정의
    from_port = ingress.value.port
    to_port = ingress.value.port
    protocol = ingress.value.protocol
    cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.instance_name}_public_sg" }
}
