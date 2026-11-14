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
from collections.abc import Iterator
from pathlib import Path

import hcl2
import yaml
from hcl2.utils import SerializationOptions

MODULE_CALL_FILE = Path("terraform/infrastructure/dungeon_studio_infrastructure.tf")
MODULE_CALL_NAME = "dungeon_studio_infrastructure"
MODULE_FILE = Path("terraform/modules/github_repository/main.tf")
WORKFLOWS = Path(".github/workflows")

# Any of these on the pull_request trigger skips some pull requests.
PULL_REQUEST_FILTERS = {"branches", "branches-ignore", "paths", "paths-ignore"}


def load_hcl(path: Path) -> dict:
    with path.open() as f:
        return hcl2.load(f, serialization_options=SerializationOptions(strip_string_quotes=True))


def load_module_call() -> dict:
    modules = load_hcl(MODULE_CALL_FILE).get("module", [])
    return next(m[MODULE_CALL_NAME] for m in modules if MODULE_CALL_NAME in m)


def load_module_locals() -> dict:
    return {k: v for block in load_hcl(MODULE_FILE).get("locals", []) for k, v in block.items()}


def required_contexts() -> set[str]:
    """Mirror the contexts main.tf's checks_refs requires across every ref."""
    module_call = load_module_call()
    checks = module_call.get("required_status_checks")
    if checks is None:
        return set()

    module_locals = load_module_locals()
    contexts = set(checks.get("contexts", []))
    if checks.get("ci_results_check", False):
        contexts.add(module_locals["ci_results_check"])
    if not module_call.get("legacy", {}).get("squash_only", False):
        contexts.add(module_locals["git_flow_source_check"])
    return contexts


def triggers(workflow: dict) -> dict:
    """Return a workflow's on: as a mapping from event to its filters."""
    # YAML 1.1 reads the bare key on as true.
    on = workflow.get("on", workflow.get(True))
    if isinstance(on, str):
        on = [on]
    if isinstance(on, list):
        return dict.fromkeys(on)
    return on or {}


def runs_on_every_pull_request(workflow: dict) -> bool:
    on = triggers(workflow)
    return "pull_request" in on and not PULL_REQUEST_FILTERS & set(on["pull_request"] or {})


def load_workflows() -> Iterator[dict]:
    for path in sorted([*WORKFLOWS.glob("*.yml"), *WORKFLOWS.glob("*.yaml")]):
        yield yaml.safe_load(path.read_text()) or {}


def reported_contexts() -> set[str]:
    # A job without a name reports under its id.
    return {
        job.get("name", job_id)
        for workflow in load_workflows()
        if runs_on_every_pull_request(workflow)
        for job_id, job in workflow.get("jobs", {}).items()
    }


def main() -> int:
    missing = sorted(required_contexts() - reported_contexts())
    for context in missing:
        print(
            f"{MODULE_CALL_FILE}: required check {context!r} matches no job in a workflow that runs on every pull request",
            file=sys.stderr,
        )
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
