resource "aws_lb" "public" {
  name               = "my-alb-${var.project}"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public_subnets[*].id

  enable_cross_zone_load_balancing = true
  security_groups                  = [aws_security_group.this.id]

  tags = {
    terraform = "true"
    Name      = "elb-${var.project}"
    Project   = var.project
  }

}

resource "aws_lb_target_group" "http" {
  name     = "my-tg-${var.project}-http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200,301"
    path                = "/elb-status"
    port                = "443"
    protocol            = "HTTPS"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    terraform = "true"
    Name      = "tg-${var.project}"
    Project   = var.project
  }


}

resource "aws_lb_target_group" "https" {
  name     = "my-tg-${var.project}-https"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.this.id

  health_check {
    enabled             = true
    healthy_threshold   = 5
    interval            = 30
    matcher             = "200,301"
    path                = "/elb-status"
    port                = "443"
    protocol            = "HTTPS"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    terraform = "true"
    Name      = "tg-${var.project}"
    Project   = var.project
  }


}

resource "aws_lb_target_group_attachment" "http" {
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = aws_instance.proxy.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "https" {
  target_group_arn = aws_lb_target_group.https.arn
  target_id        = aws_instance.proxy.id
  port             = 443
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_listener" "https" {
  certificate_arn   = aws_acm_certificate.cert.arn
  load_balancer_arn = aws_lb.public.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    target_group_arn = aws_lb_target_group.https.arn
    type             = "forward"
  }
}

resource "aws_globalaccelerator_accelerator" "this" {
  name            = "my-ga-${var.project}"
  ip_address_type = "IPV4"

  tags = {
    terraform = "true"
    Name      = "ga-${var.project}"
    Project   = var.project
  }


}

resource "aws_globalaccelerator_listener" "http" {
  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  client_affinity = "NONE"
  protocol        = "TCP"
  port_range {
    from_port = 80
    to_port   = 80
  }
}

resource "aws_globalaccelerator_listener" "https" {
  accelerator_arn = aws_globalaccelerator_accelerator.this.id
  client_affinity = "NONE"
  protocol        = "TCP"
  port_range {
    from_port = 443
    to_port   = 443
  }
}


resource "aws_globalaccelerator_endpoint_group" "http" {
  listener_arn = aws_globalaccelerator_listener.http.id
  endpoint_configuration {
    endpoint_id                    = aws_lb.public.arn
    weight                         = 100
    client_ip_preservation_enabled = true
  }
}

resource "aws_globalaccelerator_endpoint_group" "https" {
  listener_arn = aws_globalaccelerator_listener.https.id
  endpoint_configuration {
    endpoint_id                    = aws_lb.public.arn
    weight                         = 100
    client_ip_preservation_enabled = true
  }
}

