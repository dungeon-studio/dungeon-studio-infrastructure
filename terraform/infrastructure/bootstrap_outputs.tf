# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Published by terraform/bootstrap/published_outputs.tf, which says why.
data "google_storage_bucket_object_content" "bootstrap" {
  bucket = "dungeon-studio-infrastructure-tfstate"
  name   = "bootstrap-outputs.json"
}

locals {
  bootstrap = jsondecode(data.google_storage_bucket_object_content.bootstrap.content)
}
