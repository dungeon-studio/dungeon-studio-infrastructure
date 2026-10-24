# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

variable "billing_account_id" {
  type        = string
  description = "Billing account to attach to the project. Lives in bootstrap so the deployer service accounts never need billing permissions."

  validation {
    condition     = can(regex("^[0-9A-Z]{6}-[0-9A-Z]{6}-[0-9A-Z]{6}$", var.billing_account_id))
    error_message = "Billing account ID must be 18 characters: XXXXXX-XXXXXX-XXXXXX (6 alphanumeric, hyphen, 6 alphanumeric, hyphen, 6 alphanumeric)"
  }
}

variable "grafana_cloud_access_policy_token" {
  type        = string
  sensitive   = true
  description = <<-EOT
    Grafana Cloud access policy token for this run. Delete it afterwards.

    1. Open https://dungeonstudio.grafana.net/a/grafana-auth-app
    2. On dungeon-studio-infrastructure-bootstrap, choose Add token.
    3. Set a one-day expiry and copy the token.
  EOT
}
