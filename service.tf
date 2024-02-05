data "aws_ecs_cluster" "this" {
  cluster_name = var.ecs_cluster_name
}

resource "aws_ecs_service" "this" {
  name = "${var.runtime_group}-gateway"

  cluster = var.ecs_cluster_name
  desired_count = 1

  launch_type = "FARGATE"
  task_definition = aws_ecs_task_definition.this.arn

  lifecycle {
    ignore_changes = [desired_count] # Allow external changes to happen without Terraform conflicts, particularly around auto-scaling.
  }

  network_configuration {
    security_groups  = [aws_security_group.nsg_task.id]
    subnets          = var.subnets
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.id
    container_name   = "proxy"
    container_port   = "8443"
  }

  # workaround for https://github.com/hashicorp/terraform/issues/12634
  depends_on = [aws_lb_listener.http]
}

resource "aws_security_group" "nsg_lb" {
  name        = "${var.runtime_group}-${var.environment}-lb"
  description = "Allow connections from external resources while limiting connections from ${var.runtime_group}-${var.environment}-lb to internal resources"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "nsg_task" {
  name        = "${var.runtime_group}-${var.environment}-task"
  description = "Limit connections from internal resources while allowing ${var.runtime_group}-${var.environment}-task to connect to all external resources"
  vpc_id      = var.vpc_id
}

# Rules for the LB (Targets the task SG)
resource "aws_security_group_rule" "nsg_lb_egress_rule" {
  description              = "Only allow SG ${var.runtime_group}-${var.environment}-lb to connect to ${var.runtime_group}-${var.environment}-task on port 8443"
  type                     = "egress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nsg_task.id

  security_group_id = aws_security_group.nsg_lb.id
}

# Rules for the TASK (Targets the LB SG)
resource "aws_security_group_rule" "nsg_task_ingress_rule" {
  description              = "Only allow connections from SG ${var.runtime_group}-${var.environment}-lb on port 8443"
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nsg_lb.id

  security_group_id = aws_security_group.nsg_task.id
}

resource "aws_security_group_rule" "nsg_task_egress_rule" {
  description = "Allows task to establish connections to all resources"
  type        = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nsg_task.id
}
