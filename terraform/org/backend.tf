# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

terraform {
  backend "gcs" {
    bucket = "dungeon-studio-tfstate"
    prefix = "org"
  }
}
