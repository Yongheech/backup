# 보안그룹 모듈 리소스 정의

resource "aws_security_group" "this" {
  name = var.sg_name
  description = var.description

  ingress {
    description = "Allow HTTP from anywhere"
    from_port = var.ingrees_port
    to_port = var.ingrees_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ssh from anywhere"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg_name
  }
}

