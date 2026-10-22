# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

[doc("First-time setup: state backend, bootstrap layer, CI credentials.")]
bootstrap:
    scripts/bootstrap.sh

[doc("Local post-merge apply for the infrastructure layer (GCP, DNS, GitHub).")]
infrastructure:
    scripts/infrastructure.sh

[doc("Write the hook-fix App's ID and private key to each Renovate-automerged repository.")]
configure-hook-fix:
    scripts/configure-hook-fix-secrets.sh
