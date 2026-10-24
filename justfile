# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT

# Each run needs fresh Grafana Cloud and Cloudflare tokens — see README
# §Run the first-time bootstrap.
[doc("First-time setup: state backend, bootstrap layer, CI credentials.")]
bootstrap:
    scripts/bootstrap.sh

[doc("Local apply for the infrastructure layer (GCP, DNS, GitHub) when CI cannot apply it.")]
infrastructure:
    scripts/infrastructure.sh

[doc("Write the hook-fix App's ID and private key to each Renovate-automerged repository.")]
configure-hook-fix:
    scripts/configure-hook-fix-secrets.sh
