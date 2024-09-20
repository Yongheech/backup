# 모듈에 사용할 변수 정의
variable "sg_name" {
  description = "name of SG"
  type = string
  default = "tfEleven"
}

variable "description" {
  description = "description of SG"
  type = string
  default =  "Allow HTTP and SSH traffic"
}

variable "ingrees_port" {
  description = "ingress port number of SG"
  type = number
  default = 80
}