# 개선된 코드를 사용

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-2"
}
# 퍼블릭/프라이빗 서브넷 생성
module "public_subnet" {
   source = "./github/aws_vpc_public_subnet"
  #source = "github.com/Yongheech/terraform-module-repo//aws_vpc_public_subnet"

  instance_name = "tfTwentyThree"
  vpc_cidr = "172.16.0.0/20"
  subnet_cidr = "172.16.0.0/24"
  avail_zone = "ap-northeast-2a"

  inbound_ports = [
    {
      port = 22
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port = 80
    }
  ]
}

module "private_subnet" {
  source = "./github/aws_vpc_private_subnet"
  #source = "github.com/Yongheech/terraform-module-repo//aws_vpc_private_subnet"

  instance_name = "tfTwentyThree"
  vpc_id = module.public_subnet.vpc_id
  public_subnet_id = module.public_subnet.public_subnet_id
  public_igw_id = module.public_subnet.pubic_igw_id

  subnets = {
    "fastapi" = {
      cidr_block = "172.16.2.0/24"
      avail_zone = "ap-northeast-2a"
      ingress_port = [22, 8000]
    }
    "mariadb" = {
      cidr_block = "172.16.3.0/24"
      avail_zone = "ap-northeast-2c"
      ingress_port = [22, 3306]
    }
  }
}

# user_data 모듈
data "template_file" "nginx_userdata" {
  template = file("${path.module}/nginx_user_data.sh")
  vars = {
    fastapi_private_ip = aws_instance.tfTwentyThree2.private_ip
  }
}

data "template_file" "fastapi_userdata" {
  template = file("${path.module}/fastapi_user_data.sh")
  vars = {
    mariadb_private_ip = aws_instance.tfTwentyThree3.private_ip
  }
}

# 자기순환 참조(cycle reference)때문에 실행시 오류 발생!
# 테라폼에서 지원하는 프로비저너를 사용해야 함
# 즉, 인스턴스가 만들어진 후여야 mariadb 설정 가능
# data "template_file" "mariadb_userdata" {
#   template = file("${path.module}/mariadb_user_data.sh")
#   vars = {
#     mariadb_private_ip = aws_instance.tfTwentyThree2.private_ip
#   }
# }



# 각 서브넷에 대한 인스턴스 생성
resource "aws_instance" "tfTwentyThree1" {
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

  tags = { Name = "tfTwentyThree1" }

  user_data = data.template_file.nginx_userdata.rendered
}

output "nginx_public_ip" {
  value = aws_instance.tfTwentyThree1.public_ip
}

#---

resource "aws_instance" "tfTwentyThree2" {
  ami           = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = "clouds2024"

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    delete_on_termination = true  # 인스턴스 종료시 볼륨도 삭제
  }

  vpc_security_group_ids = [module.private_subnet.private_sg_fastapi_id]
  subnet_id = module.private_subnet.private_subnet_fastapi_id
  associate_public_ip_address = false

  tags = { Name = "tfTwentyThree2" }

  user_data = data.template_file.fastapi_userdata.rendered
}

#---
output "fastapi_private_ip" {
  value = aws_instance.tfTwentyThree3.private_ip
}

resource "aws_instance" "tfTwentyThree3" {
  ami           = "ami-056a29f2eddc40520"
  instance_type = "t2.micro"
  key_name      = "clouds2024"

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    delete_on_termination = true  # 인스턴스 종료시 볼륨도 삭제
  }

  vpc_security_group_ids = [module.private_subnet.private_sg_mariadb_id]
  subnet_id = module.private_subnet.private_subnet_mariadb_id
  associate_public_ip_address = false

  tags = { Name = "tfTwentyThree2" }

  user_data = data.template_file.mariadb_userdata.rendered
}

output "mariadb_private_ip" {
  value = aws_instance.tfTwentyThree3.private_ip
}
