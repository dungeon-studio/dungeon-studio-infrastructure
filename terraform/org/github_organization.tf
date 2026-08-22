# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# The layer's only GitHub read until the org's repositories land here. It
# exists so an apply exercises the App credentials rather than configuring a
# provider nothing calls. summary_only holds it to GET /orgs/{org}, which the
# App's mandatory Metadata permission already covers; dropping it adds reads
# of the member and repository lists.
data "github_organization" "org" {
  name         = local.github_owner
  summary_only = true
}
