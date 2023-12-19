data "aws_ami" "amazon-linux-2023" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "^al2023-ami-2023*"

  filter {
    name   = "description"
    values = ["Amazon Linux 2023 AMI*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }


  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "azs" {
  state = "available"
}

data "aws_region" "current" {}

#data "terraform_remote_state" "global" {
#  backend = "local"
#
#  config = {
#    path = "${path.module}/../../global/terraform.tfstate"
#  }
#}


