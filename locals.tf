locals {
  log_prefix = "/fargate/kong/${var.runtime_group}"
  cluster_hostname = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<authority>[^/?#]*))?", var.control_plane_address).authority
  telemetry_hostname = regex("^(?:(?P<scheme>[^:/?#]+):)?(?://(?P<authority>[^/?#]*))?", var.telemetry_address).authority
}
