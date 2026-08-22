# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Not Terraform-managed: this layer keeps its own state in the bucket, so
# managing the bucket here would be circular. Its lifecycle belongs to
# scripts/bootstrap.sh.
data "google_storage_bucket" "state" {
  name = local.state_bucket
}
