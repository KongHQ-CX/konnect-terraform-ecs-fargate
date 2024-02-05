variable "kong_image_repository" {}
variable "kong_image_tag" {}
variable "runtime_group" {}
variable "cluster_cert_secret_arn" {}
variable "cluster_cert_key_secret_arn" {}
variable "vpc_id" {}
variable "subnets" {}
variable "ecs_cluster_name" {}
variable "alb_certificate_arn" {}
variable "control_plane_address" {}
variable "telemetry_address" {}

variable "region" {
  description = "AWS Region that will host this stack"
  type = string
  default = "eu-west-1"
}

variable "environment" {
  description = "Environment label / tags to apply"
  type = string
  default = "production"
}

variable "log_retention_days" {
  description = "How long, in days, to keep container logs in CloudWatch"
  type = number
  default = 7
}
