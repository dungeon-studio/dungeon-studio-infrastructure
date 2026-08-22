# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Exists so an apply exercises the App credentials; a provider no resource
# calls is never asked to authenticate. summary_only holds the read to
# GET /orgs/{org}, which the App's mandatory Metadata permission covers.
# Without it the data source also lists members and repositories.
data "github_organization" "org" {
  name         = local.github_owner
  summary_only = true
}
