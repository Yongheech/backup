variable "vpc_id" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "subnets" {
  type = map(object({
    cidr_block = string
    avail_zone = string
    ingress_port = list(number)
  }))
}

variable "public_subnet_id" {
  type = string
}

variable "public_igw_id" {
  type = string
}



