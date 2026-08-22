# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Stubs until the layers they drive exist. Each names the issue that fills it
# in so `just <recipe>` points at the work rather than failing opaquely.

issues := "https://github.com/dungeon-studio/dungeon-studio-infrastructure/issues"

[doc("Manual surface: state backend, bootstrap layer, CI credentials.")]
bootstrap:
    @echo "Not implemented — terraform/bootstrap/ lands in {{ issues }}/2"
    @exit 1

[doc("Local post-merge apply for the org layer (GCP baseline, DNS, GitHub).")]
org:
    @echo "Not implemented — terraform/org/ lands in {{ issues }}/5"
    @exit 1
