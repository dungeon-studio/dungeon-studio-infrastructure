# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Not Terraform-managed: this layer keeps its own state in the bucket, so
# managing the bucket here would be circular. Its lifecycle, including object
# versioning, belongs to scripts/bootstrap-terraform-state.sh.
data "google_storage_bucket" "state" {
  name = "dungeon-studio-tfstate"
}
