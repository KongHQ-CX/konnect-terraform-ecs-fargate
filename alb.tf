# note that this creates the alb, target group, and access logs
# the listeners are defined in lb-http.tf and lb-https.tf
# delete either of these if your app doesn't need them
# but you need at least one

# Whether the application is available on the public internet,
# also will determine which subnets will be used (public or private)
variable "internal" {
  default = false
}

# The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused
variable "deregistration_delay" {
  default = "30"
}

# The path to the health check for the load balancer to know if the container(s) are ready
variable "health_check" {
  default = "/"
}

variable "health_check_protocol" {
  default = "HTTPS"
}

# How often to check the liveliness of the container
variable "health_check_interval" {
  default = "30"
}

# How long to wait for the response on the health check path
variable "health_check_timeout" {
  default = "10"
}

# What HTTP response code to listen for
variable "health_check_matcher" {
  default = "200,404"
}

variable "lb_access_logs_expiration_days" {
  default = "3"
}

resource "aws_alb" "main" {
  name = "konnect-${var.runtime_group}"

  # launch lbs in public or private subnets based on "internal" variable
  internal = var.internal
  subnets = var.subnets
  security_groups = [aws_security_group.nsg_lb.id]
}

# adds an http listener to the load balancer and allows ingress
# (delete this file if you only want https)

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.main.id
  port              = 443
  protocol          = "HTTPS"

  certificate_arn = var.alb_certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }
}

resource "aws_security_group_rule" "ingress_lb_http" {
  type              = "ingress"
  description       = "https"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"] # YOUR public IP address
  security_group_id = aws_security_group.nsg_lb.id
}

resource "aws_alb_target_group" "main" {
  name                 = "konnect-${var.runtime_group}"
  port                 = 443
  protocol             = "HTTPS"
  vpc_id               = var.vpc_id
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay

  health_check {
    path                = var.health_check
    matcher             = var.health_check_matcher
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    protocol            = var.health_check_protocol
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}

data "aws_elb_service_account" "main" {
}

# The load balancer DNS name
output "lb_dns" {
  value = aws_alb.main.dns_name
}