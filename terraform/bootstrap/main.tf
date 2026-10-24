# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

terraform {
  required_version = ">= 1.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.50"
    }
  }
}

provider "google" {
  project = local.project_id
  region  = local.region
}

provider "grafana" {
  cloud_access_policy_token = var.grafana_cloud_access_policy_token
}
