# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Grafana queries Cloud Monitoring live, which is the only way to see metrics
# Cloud Run records on its own, such as container startup latency. Each query
# names its project; the default only seeds the editor.
resource "grafana_data_source" "gcp_cloud_monitoring" {
  type = "stackdriver"
  name = "GCP Cloud Monitoring"
  uid  = "gcp-cloud-monitoring"

  # The private key is absent because pull request plans can read this
  # layer's state; scripts/configure-grafana-gcp-credentials.sh sets it as
  # the operator.
  json_data_encoded = jsonencode({
    authenticationType = "jwt"
    defaultProject     = "dungeon-studio-genshin-dev"
    clientEmail        = local.bootstrap.grafana_gcp_reader_email
    tokenUri           = "https://oauth2.googleapis.com/token"
  })

  lifecycle {
    # Grafana preserves secure fields omitted from an update, so applies leave
    # the operator-set key in place.
    ignore_changes = [secure_json_data_encoded]
  }
}
