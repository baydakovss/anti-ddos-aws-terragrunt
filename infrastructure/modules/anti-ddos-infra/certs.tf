resource "aws_acm_certificate" "cert" {
  private_key       = file(var.private_key)
  certificate_body  = file(var.certificate_body)
  certificate_chain = file(var.certificate_chain)
}

