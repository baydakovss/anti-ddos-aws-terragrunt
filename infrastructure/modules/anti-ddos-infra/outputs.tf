output "_project" {
  value = var.project
}

output "_region" {
  value = data.aws_region.current.name
}

output "ec2_public_ips" {
  #value = aws_instance.proxy.*.public_ip
  value = aws_eip_association.this.public_ip
}

output "ga_ips" {
  value = aws_globalaccelerator_accelerator.this.ip_sets
}

output "whitelist" {
  value = aws_globalaccelerator_accelerator.this.ip_sets
}


