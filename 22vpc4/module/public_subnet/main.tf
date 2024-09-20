# VPC 생성
resource "aws_vpc" "vpc" {
  cidr_block = "172.16.0.0/20"
  enable_dns_hostnames =  true
  enable_dns_support = true

  tags = { Name = "tf_vpc" }
}

# 서브넷 생성
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "172.16.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = { Name = "tf_public_subnet" }
}

# 인터넷 게이트웨이
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = { Name = "tf_igw" }
}

# 라우팅 테이블 생성 및 인터넷 게이트웨이 연결
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "public_rtbasso" {
  route_table_id = aws_route_table.public_rtb.id
  subnet_id = aws_subnet.public_subnet.id
}

# 보안그룹 생성
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 주의! 접속 위치 제한 필요!
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tf_public_sg" }
}
