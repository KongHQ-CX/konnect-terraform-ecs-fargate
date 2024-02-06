##
## THIS MODULE ONLY ACTIVATES IF CLUSTER CERT AND CLUSTER CERT KEY ARNS AREN'T PROVIDED
##

resource "tls_self_signed_cert" "cluster_cert" {
  count = var.cluster_cert_secret_arn == null ? 1 : 0

  private_key_pem = tls_private_key.cluster_key[0].private_key_pem

  subject {
    common_name = "kong_clustering"
  }

  validity_period_hours = 8766  # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

resource "aws_secretsmanager_secret" "cluster_cert" {
  count = var.cluster_cert_secret_arn == null ? 1 : 0

  name = "konnect/clustering_certificates/${var.runtime_group}/cert"
}

resource "aws_secretsmanager_secret_version" "cluster_cert" {
  count = var.cluster_cert_secret_arn == null ? 1 : 0

  secret_id     = aws_secretsmanager_secret.cluster_cert[0].id
  secret_string = tls_self_signed_cert.cluster_cert[0].cert_pem
}


# RSA key of size 4096 bits
resource "tls_private_key" "cluster_key" {
  count = var.cluster_cert_key_secret_arn == null ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_secretsmanager_secret" "cluster_key" {
  count = var.cluster_cert_key_secret_arn == null ? 1 : 0

  name = "konnect/clustering_certificates/${var.runtime_group}/key"
}

resource "aws_secretsmanager_secret_version" "cluster_key" {
  count = var.cluster_cert_key_secret_arn == null ? 1 : 0

  secret_id     = aws_secretsmanager_secret.cluster_key[0].id
  secret_string = tls_private_key.cluster_key[0].private_key_pem
}

# The following example shows how to issue an HTTP POST request
# supplying an optional request body.
data "http" "upload_certificate" {
  count = var.cluster_cert_secret_arn == null ? 1 : 0

  url    = "https://eu.api.konghq.com/v2/control-planes/${var.control_plane_id}/dp-client-certificates"
  method = "POST"
  request_headers = {
    Authorization = "Bearer ${var.konnect_pat}"
    Accept = "application/json"
    Content-Type = "application/json"
  }

  # Optional request body
  request_body = jsonencode({ cert = tls_self_signed_cert.cluster_cert[0].cert_pem })
}

resource "null_resource" "upload_certificate" {
  # On success, this will attempt to execute the true command in the
  # shell environment running terraform.
  # On failure, this will attempt to execute the false command in the
  # shell environment running terraform.
  provisioner "local-exec" {
    command = contains([201], data.http.upload_certificate[0].status_code)
  }
}
