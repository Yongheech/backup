# 프라이빗 서브넷 생성
resource "aws_subnet" "subnet3" {
  vpc_id = var.vpc_id
  cidr_block = "172.16.3.0/24"
  availability_zone = "ap-northeast-2c"

  tags = { Name = "tfNineteen_subnet3" }
}

# NAT 게이트웨이 생성 및 연결
resource "aws_eip" "eip" {
  domain = "vpc"
  depends_on = [var.igw_id]

  tags = { Name = "tfNineteen_eip" }
}

resource "aws_nat_gateway" "natgw" {
  subnet_id = var.public_subnet_id
  allocation_id = aws_eip.eip.id

  tags = { Name = "tfNineteen_natgw" }
}

# 라우팅 테이블 생성 및 NAT 게이트웨이 연결
resource "aws_route_table" "rtb3" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }
}

# 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "rtb3asso" {
  route_table_id = aws_route_table.rtb3.id
  subnet_id = aws_subnet.subnet3.id
}

# 보안그룹 생성
resource "aws_security_group" "sg3" {
  vpc_id = var.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "tfNineteen_sg3" }
}