# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

locals {
  github_owner = "dungeon-studio"

  dungeon_studio_zone_id = local.bootstrap.cloudflare_zone_id
}
