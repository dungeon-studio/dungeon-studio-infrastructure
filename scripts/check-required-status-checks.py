#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
"""Fail when this repository requires a status check no pull request reports.

The checks rulesets have no bypass actors, so a required context that never
reports blocks every merge, the admin's included. Each context the module call
requires must match the name of a job in a workflow that runs on every pull
request.
"""

import sys
from pathlib import Path

import hcl2
import yaml
from hcl2.utils import SerializationOptions

MODULE_FILE = Path("terraform/infrastructure/dungeon_studio_infrastructure.tf")
MODULE_NAME = "dungeon_studio_infrastructure"
WORKFLOWS = Path(".github/workflows")

# Mirror the contexts terraform/modules/github_repository/main.tf adds to
# checks_refs beyond required_status_checks.contexts.
CI_RESULTS_CHECK = "Check CI results"
GIT_FLOW_SOURCE_CHECK = "Check Git flow source branch"

# Any of these on the pull_request trigger skips some pull requests.
PULL_REQUEST_FILTERS = {"branches", "branches-ignore", "paths", "paths-ignore"}


def required_contexts() -> set[str]:
    with MODULE_FILE.open() as f:
        tf = hcl2.load(f, serialization_options=SerializationOptions(strip_string_quotes=True))
    module = next(m[MODULE_NAME] for m in tf.get("module", []) if MODULE_NAME in m)

    checks = module.get("required_status_checks")
    if checks is None:
        return set()

    contexts = set(checks.get("contexts", []))
    if checks.get("ci_results_check", False):
        contexts.add(CI_RESULTS_CHECK)
    if not module.get("legacy", {}).get("squash_only", False):
        contexts.add(GIT_FLOW_SOURCE_CHECK)
    return contexts


def runs_on_every_pull_request(workflow: dict) -> bool:
    # YAML 1.1 reads the bare key on as true.
    triggers = workflow.get("on", workflow.get(True))
    if isinstance(triggers, str):
        return triggers == "pull_request"
    if isinstance(triggers, list):
        return "pull_request" in triggers
    if isinstance(triggers, dict) and "pull_request" in triggers:
        return not PULL_REQUEST_FILTERS & set(triggers["pull_request"] or {})
    return False


def reported_contexts() -> set[str]:
    names = set()
    for path in sorted([*WORKFLOWS.glob("*.yml"), *WORKFLOWS.glob("*.yaml")]):
        workflow = yaml.safe_load(path.read_text())
        if runs_on_every_pull_request(workflow):
            # A job without a name reports under its id.
            names.update(job.get("name", job_id) for job_id, job in workflow.get("jobs", {}).items())
    return names


def main() -> int:
    missing = sorted(required_contexts() - reported_contexts())
    for context in missing:
        print(
            f"{MODULE_FILE}: required check {context!r} matches no job in a workflow that runs on every pull request",
            file=sys.stderr,
        )
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
