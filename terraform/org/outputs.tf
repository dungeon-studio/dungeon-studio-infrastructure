# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

output "github_organization_id" {
  value       = data.github_organization.org.id
  description = "GitHub's numeric ID for the org, read back as proof the App authenticated"
  sensitive   = false
}
