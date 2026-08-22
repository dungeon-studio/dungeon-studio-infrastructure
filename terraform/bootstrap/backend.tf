# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# terraform/org/ takes the "org" prefix in the same bucket.
terraform {
  backend "gcs" {
    bucket = "dungeon-studio-tfstate"
    prefix = "bootstrap"
  }
}
