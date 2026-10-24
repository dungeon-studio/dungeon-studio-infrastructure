<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# Create the Grafana Cloud bootstrap token

`just bootstrap` creates Grafana credentials in the `dungeonstudio` stack and
writes them to Secret Manager, using a Grafana Cloud access policy token. That
token can create and delete access policies, so create one per run and delete
it afterwards.

You need the Admin role in the `dungeonstudio` stack.

## Create the access policy

Do this once.

1. Open [Cloud access policies] and select **Create access policy**.

2. Name it `dungeon-studio-infrastructure-bootstrap`.

3. Select **Add scope** and tick:

   - `stacks`: **read**
   - `stack-service-accounts`: **write**
   - `accesspolicies`: **read**, **write**, **delete**

   Leave every other scope unchecked, then select **Create**.

## Run bootstrap

1. In [Cloud access policies], choose **Add token** on
   `dungeon-studio-infrastructure-bootstrap`. Set a one-day expiry and copy
   the token; Grafana shows it once.

2. Run `just bootstrap` and paste the token at the
   `var.grafana_cloud_access_policy_token` prompt. To run without a
   terminal, export `TF_VAR_grafana_cloud_access_policy_token` first.

3. Delete the token.

## Recover from a missing scope

Without `accesspolicies:read`, bootstrap creates a push policy and then
fails, leaving it tainted. Add the scope to the policy, add a new token, and
re-run; Terraform replaces the tainted policy.

[Cloud access policies]: https://dungeonstudio.grafana.net/a/grafana-auth-app
