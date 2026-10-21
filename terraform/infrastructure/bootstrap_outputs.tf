# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Non-secret bootstrap values, published by
# terraform/bootstrap/published_outputs.tf. Read as an object rather than
# through terraform_remote_state because the deployers hold no read on
# bootstrap's state; plan runs on every pull request, and that state defines
# their own credentials.
data "google_storage_bucket_object_content" "bootstrap" {
  bucket = "dungeon-studio-infrastructure-tfstate"
  name   = "bootstrap-outputs.json"
}

locals {
  bootstrap = jsondecode(data.google_storage_bucket_object_content.bootstrap.content)
}
