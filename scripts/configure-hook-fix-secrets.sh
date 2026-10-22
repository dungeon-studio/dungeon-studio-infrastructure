#!/bin/bash
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
#
# Writes the hook-fix GitHub App's ID and private key as Actions secrets to
# each repository Renovate automerges. Terraform would keep the key in state,
# so this runs out-of-band. Overwriting on every run is how a rotated key
# reaches each repository.

set -euo pipefail

HOOK_FIX_APP_ID="${HOOK_FIX_APP_ID:-5422895}"

# Match the App's installation. A repository listed here without it gets
# credentials that cannot push.
REPOS=(
  dungeon-studio/genshin.dungeon.studio
)

die() {
  echo "error: $*" >&2
  exit 1
}

check_preconditions() {
  command -v gh >/dev/null || die "gh not found in PATH"
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated; run 'gh auth login'"
}

check_app_id() {
  [[ "${HOOK_FIX_APP_ID}" =~ ^[0-9]+$ ]] ||
    die "HOOK_FIX_APP_ID must be digits, got '${HOOK_FIX_APP_ID}'"
}

resolve_private_key_path() {
  local path="${HOOK_FIX_APP_PRIVATE_KEY_PATH:-}"

  if [[ -z "${path}" ]]; then
    [[ -t 0 ]] || die "HOOK_FIX_APP_PRIVATE_KEY_PATH is unset and stdin is not a terminal"
    read -rp "Path to the hook-fix App's private key .pem: " path
  fi

  # read hands back the tilde the shell would have expanded.
  path="${path/#\~/${HOME}}"

  [[ -r "${path}" ]] || die "cannot read ${path}"

  # A wrong file otherwise surfaces only when the first fix push is refused.
  grep -q -- '-----BEGIN .*PRIVATE KEY-----' "${path}" ||
    die "${path} is not a PEM private key; see docs/how-to/create-hook-fix-github-app.md"

  printf '%s' "${path}"
}

set_hook_fix_secrets() {
  local repo="$1" key_path="$2"

  echo "Setting HOOK_FIX_APP_ID and HOOK_FIX_APP_PRIVATE_KEY on ${repo}"
  gh secret set HOOK_FIX_APP_ID --repo "${repo}" --body "${HOOK_FIX_APP_ID}"
  # stdin keeps the key out of the process list.
  gh secret set HOOK_FIX_APP_PRIVATE_KEY --repo "${repo}" <"${key_path}"
}

main() {
  check_preconditions
  check_app_id

  local key_path repo
  key_path="$(resolve_private_key_path)"

  for repo in "${REPOS[@]}"; do
    set_hook_fix_secrets "${repo}" "${key_path}"
  done

  echo "Shred ${key_path} once the secrets are set."
}

main "$@"
