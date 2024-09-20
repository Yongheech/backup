resource "aws_subnet" "private_subnet" {
  for_each = var.subnets
  vpc_id = var.vpc_id
  cidr_block = each.value.cidr_block
  availability_zone = each.value.avail_zone

  # 서브넷 생성시 키이름을 포함시킴 : ${each.key}
  tags = { Name = "${var.instance_name}_private_subnet_${each.key}"}
}

#----

# NAT 게이트웨이/라우팅 테이블 관련 코드 추가 필요!

# NAT 게이트웨이 생성 및 연결
resource "aws_eip" "eip" {
  for_each = var.subnets
  domain = "vpc"
  depends_on = [var.public_igw_id]

  tags = { Name = "${var.instance_name}_eip_${each.key}"}
}

resource "aws_nat_gateway" "natgw" {
  for_each = var.subnets
  subnet_id = var.public_subnet_id
  allocation_id = aws_eip.eip[each.key].id

  tags = { Name = "${var.instance_name}_natgw_${each.key}"}
}

# 라우트 테이블 생성 및 NAT 게이트웨이 연결
resource "aws_route_table" "private_rtb" {
  for_each = var.subnets
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw[each.key].id
  }

  tags = { Name = "${var.instance_name}_privatertb_${each.key}"}
}

# 프라이빗 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "private_rtb_asso" {
  for_each = var.subnets
  route_table_id = aws_route_table.private_rtb[each.key].id
  subnet_id = aws_subnet.private_subnet[each.key].id
}

#---
# 보안그룹 생성
resource "aws_security_group" "private_sg" {
  for_each = var.subnets
  name = "${var.instance_name}_private_sg_${each.key}"
  vpc_id = var.vpc_id

  # ingress 추가 필요!

  dynamic "ingress"  {
    for_each = each.value.ingress_port
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "${var.instance_name}_private_sg_${each.key}" }
  }
