variable "vpc_cidr" {
  default = ""
}

variable "public_subnet_cidrs" {
  default = []
}

variable "project" {
  type = string
}

variable "whitelist" {
  type = list(any)
}

variable "under_attack" {
  type = number
  default = 0
  # 0 - waf is not associated to alb
}

variable "user_data" {
  type = string
  default = ""
}
variable "private_key" {
  type = string
  default = ""
}

variable "certificate_body" {
  type = string
  default = ""
}

variable "certificate_chain" {
  type = string
  default = ""
}




