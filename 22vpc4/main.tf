# 퍼블릭 서브넷, 프라이빗 서브넷 생성
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# 퍼블릭 서브넷
module "public_subnet" {
  source = "./module/public_subnet"
}

# 프라이빗 서브넷
module "private_subnet1" {
  source = "./module/private_subnet1"
  vpc_id = module.public_subnet.vpc_id
  igw_id = module.public_subnet.igw_id
  public_subnet_id = module.public_subnet.public_subnet_id
}

# 프라이빗 서브넷
module "private_subnet2" {
  source = "./module/private_subnet2"
  vpc_id = module.public_subnet.vpc_id
  igw_id = module.public_subnet.igw_id
  public_subnet_id = module.public_subnet.public_subnet_id
}

# user_data 모듈
# fastapi의 private ip를 nginx_user_data.sh에 삽입
data "template_file" "nginx_userdata" {
  template = file("${path.module}/nginx_user_data.sh")
  vars = {
    fastapi_private_ip = aws_instance.tfTwentyOne2.private_ip
  }
}

# mariadb의 private ip를 fastapi_user_data.sh에 삽입
data "template_file" "fastapi_userdata" {
  template = file("${path.module}/fastapi_user_data.sh")
  vars = {
    mariadb_private_ip = aws_instance.tfTwentyOne3.private_ip
  }
}

# EC2 인스턴스 생성
resource "aws_instance" "tfTwentyOne1" {
  ami           = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = "clouds2024"

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    delete_on_termination = true  # 인스턴스 종료시 볼륨도 삭제
  }

  vpc_security_group_ids = [module.public_subnet.public_sg_id]
  subnet_id = module.public_subnet.public_subnet_id
  associate_public_ip_address = true

  tags = { Name = "tfTwentyOne1" }

  user_data = data.template_file.nginx_userdata.rendered
}

output "nginx_public_ip" {
  value = aws_instance.tfTwentyOne1.public_ip
}

# ---

# EC2 인스턴스 2 생성
resource "aws_instance" "tfTwentyOne2" {
  ami           = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = "clouds2024"

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    delete_on_termination = true  # 인스턴스 종료시 볼륨도 삭제
  }

  vpc_security_group_ids = [module.private_subnet1.private1_sg_id]
  subnet_id = module.private_subnet1.private1_subnet_id
  associate_public_ip_address = false

  tags = { Name = "tfTwentyOne2" }

  user_data = data.template_file.fastapi_userdata.rendered
}

output "fastapi_private_ip" {
  value = aws_instance.tfTwentyOne2.private_ip
}

# ---

# EC2 인스턴스 3 생성
resource "aws_instance" "tfTwentyOne3" {
  ami           = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = "clouds2024"

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    delete_on_termination = true  # 인스턴스 종료시 볼륨도 삭제
  }

  vpc_security_group_ids = [module.private_subnet2.private2_sg_id]
  subnet_id = module.private_subnet2.private2_subnet_id
  associate_public_ip_address = false

  tags = { Name = "tfTwentyOne3" }

  user_data = filebase64("${path.module}/mariadb_user_data.sh")

}

output "mariadb_private_ip" {
  value = aws_instance.tfTwentyOne3.private_ip
}
