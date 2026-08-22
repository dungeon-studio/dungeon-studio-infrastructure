# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

[doc("First-time setup: state backend, bootstrap layer, CI credentials.")]
bootstrap:
    scripts/bootstrap.sh

[doc("Local post-merge apply for the org layer (GCP baseline, DNS, GitHub).")]
org:
    scripts/org.sh
