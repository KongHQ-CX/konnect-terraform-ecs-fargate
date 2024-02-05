data "aws_availability_zones" "available" {}

data "aws_partition" "current" {}

data "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"
}
