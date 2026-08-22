# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

issues_url := "https://github.com/dungeon-studio/dungeon-studio-infrastructure/issues"

_unimplemented layer issue:
    @echo "Not implemented — {{ layer }} lands in {{ issues_url }}/{{ issue }}"
    @exit 1

# Every step is idempotent; safe to re-run after a partial failure.
[doc("First-time setup: state backend, bootstrap layer, CI credentials.")]
bootstrap:
    scripts/bootstrap-terraform-state.sh
    terraform -chdir=terraform/bootstrap init
    terraform -chdir=terraform/bootstrap apply

[doc("Local post-merge apply for the org layer (GCP baseline, DNS, GitHub).")]
org: (_unimplemented "terraform/org/" "5")
