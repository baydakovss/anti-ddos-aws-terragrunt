resource "aws_instance" "proxy" {
  ami                  = data.aws_ami.amazon-linux-2023.id
  instance_type        = "t3.micro"
  iam_instance_profile = "myInstanceRole"
  #iam_instance_profile   = aws_iam_instance_profile.this.name
  subnet_id              = aws_subnet.public_subnets[1].id
  vpc_security_group_ids = [aws_security_group.this.id]
  #key_name               = "myNVKP"

  lifecycle {
    ignore_changes = [ami]
    create_before_destroy = true
  }

  user_data_replace_on_change = true

  tags = {
    terraform = "true"
    Name      = var.project
    Project   = var.project
  }

  #user_data = file("~/sources/github/terragrunt/my-terragrunt/infrastructure/assets/INSTALL.sh")
  #user_data = file("${local.user_data}")
  user_data = file("${var.user_data}")

  provisioner "local-exec" {
    command = "sleep 40" # wait for instance profile to appear due to https://github.com/terraform-providers/terraform-provider-aws/issues/838
  }

}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.proxy.id
  allocation_id = aws_eip.my_eip.id
}

