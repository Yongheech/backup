variable "instance_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "avail_zone" {
  type = string
}

variable "inbound_ports" {
  type = list(object({
    port = number
    protocol = optional(string, "tcp") # optional : >= terraform 1.3.0
    cidr_blocks = optional(list(string), ["0.0.0.0/0"])
  }))
}