terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# 보안그룹 모듈
# github.com/소유자/저장소이름//모듈디렉토리
module "security_group" {
  source = "github.com/Yongheech/terraform-module-repo.git//security_group"
  sg_name = "tfTwelve_sg"
  description = "Allow MariaDB and SSH traffic"
  ingrees_port = 3306
}


# EC2 인스턴스 모듈
module "ec2_instance" {
  source = "github.com/Yongheech/terraform-module-repo.git//ec2_instance_mariadb"
  ami = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = "clouds2024"
  instance_name = "tfTwelve"
  security_group_id = module.security_group.security_group_id
}

# 결과 출력

output "secrity_group_id" {
  value = module.security_group.security_group_id
}

output "public_ip" {
  value = module.ec2_instance.public_ip
}