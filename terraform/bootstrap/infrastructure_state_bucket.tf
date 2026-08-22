# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# A resource, not a data source like the bootstrap bucket: this layer's state
# does not live here, so nothing is circular.
#
# A second bucket rather than a second prefix, because deployer grants are
# bucket-wide and GCS has no per-prefix ACL. One shared bucket would put
# bootstrap's state in reach of the deployers — read on every pull request,
# write on every merge.
resource "google_storage_bucket" "infrastructure_state" {
  project  = google_project.infrastructure.project_id
  name     = local.infrastructure_state_bucket
  location = local.region

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}
