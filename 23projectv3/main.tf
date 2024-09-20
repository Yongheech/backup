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
    #fastapi_private_ip = aws_instance.tfTwentyThree2.private_ip
    fastapi_private_ip = "[127.0.0.1]" # 플레이스홀더
  }
}

data "template_file" "fastapi_userdata" {
  template = file("${path.module}/fastapi_user_data.sh")
  vars = {
    #mariadb_private_ip = aws_instance.tfTwentyThree3.private_ip
    mariadb_private_ip = "[127.0.0.1]"
  }
}

# 자기순환 참조(cycle reference)때문에 실행시 오류 발생!
# 테라폼에서 지원하는 local-exec/remote-exex 프로비저너를 사용해야 함
# 즉, 인스턴스가 만들어진 후여야 mariadb 설정 가능
# nginx 생성 -> fastapi 생성 -> mariadb 생성
# -> nginx에 ssh 로그인 후 default.conf 수정
# -> fastapi에 ssh 로그인 후 main.py 수정
# -> mariadb에 ssh 로그인 후 50-server.cnf 수정
# fastapi, mariadb에 bastion host 방식으로 접속하려면
# 추가적으로 pem 파일을 nginx에 업로드해야 함! - 보안상 번거로움
# 본 예제에서는 인스턴스 생성까지만 테라폼이 담당하고,
# 추가 수정작업은 직접 엔지니어가 개입해서 처리하는 것으로 마무리

data "template_file" "mariadb_userdata" {
  template = file("${path.module}/mariadb_user_data.sh")
  vars = {
    #fastapi_private_ip = aws_instance.tfTwentyThree3.private_ip
    fastapi_private_ip = "[127.0.0.1]"
  }
}



# 각 서브넷에 대한 인스턴스 생성

# 각 서브넷에 대한 인스턴스 생성
# 로컬 변수 블록 정의 - 코드내에서 여러번 참조 가능
locals {
  instances = {
    nginx = {
      name = "tfTwentyThree1"
      ami = "ami-056a29f2eddc40520"
      ec2_type = "t2.micro"
      key_name = "clouds2024"
      subnet_id = module.public_subnet.public_subnet_id
      sg_id = module.public_subnet.public_sg_id
      public_ip = true
      user_data = data.template_file.nginx_userdata.rendered
    },
    fastapi = {
      name = "tfTwentyThree2"
      ami = "ami-056a29f2eddc40520"
      ec2_type = "t2.micro"
      key_name = "clouds2024"
      subnet_id = module.private_subnet.private_subnet_ids["fastapi"]
      sg_id = module.private_subnet.private_sg_ids["fastapi"]
      public_ip = false
      user_data = data.template_file.fastapi_userdata.rendered
    },
    mariadb = {
      name = "tfTwentyThree3"
      ami = "ami-056a29f2eddc40520"
      ec2_type = "t2.micro"
      key_name = "clouds2024"
      subnet_id = module.private_subnet.private_subnet_ids["mariadb"]
      sg_id = module.private_subnet.private_sg_ids["mariadb"]
      public_ip = false
      user_data = data.template_file.mariadb_userdata.rendered
    }
  }
}







resource "aws_instance" "instances" {
  for_each      = local.instances
  ami           = each.value.ami
  instance_type = each.value.ec2_type
  key_name      = each.value.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    delete_on_termination = true  # 인스턴스 종료시 볼륨도 삭제
  }

  subnet_id = each.value.subnet_id
  vpc_security_group_ids = [each.value.sg_id]
  associate_public_ip_address = each.value.public_ip

  tags = { Name = "${each.value.name}_${each.key}" }

  user_data = each.value.user_data
}

# 생선된 각 인스턴스의 퍼블릭/프라이빗 IP를 이름과 함께 출력
output "instance_ips" {
  value = {
    for key, instance in aws_instance.instances: key => {
        name = instance.tags.Name
        ip = instance.associate_public_ip_address ? instance.public_ip  : instance.private_ip
    }
  }
}



