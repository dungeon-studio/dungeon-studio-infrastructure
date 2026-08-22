# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Terraform-managed, unlike the bootstrap bucket: this layer's state does not
# live here, so there is no circularity for scripts/bootstrap.sh to break.
#
# It is a second bucket rather than a second prefix because the deployer
# grants are bucket-wide. GCS has no per-prefix ACL, so one bucket would put
# the state that defines the deployers within reach of the credentials it
# defines — read on every pull request, write on every merge.
resource "google_storage_bucket" "org_state" {
  project  = google_project.infrastructure.project_id
  name     = local.org_state_bucket
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
