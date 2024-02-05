# resource "aws_kms_key" "this" {
#   description             = "${var.runtime_group} Global Encryption Key"
#   deletion_window_in_days = 7
# }

# resource "aws_cloudwatch_log_group" "this" {
#   name = local.log_prefix
#   retention_in_days = var.log_retention_days
# }

# resource "aws_ecs_cluster" "this" {
#   name = "${var.runtime_group}-cluster"

#   configuration {
#     execute_command_configuration {
#       kms_key_id = aws_kms_key.this.arn
#       logging    = "OVERRIDE"

#       log_configuration {
#         cloud_watch_encryption_enabled = true
#         cloud_watch_log_group_name     = aws_cloudwatch_log_group.this.name
#       }
#     }
#   }
# }

# resource "aws_ecs_cluster_capacity_providers" "this" {
#   cluster_name = aws_ecs_cluster.this.name

#   capacity_providers = ["FARGATE_SPOT", "FARGATE"]

#   default_capacity_provider_strategy {
#     capacity_provider = "FARGATE_SPOT"
#   }
# }
