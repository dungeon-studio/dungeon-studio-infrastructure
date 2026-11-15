#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com>
# SPDX-License-Identifier: MIT
"""Fail when a required status check names no job that runs on every pull request.

The checks rulesets have no bypass actors, so a required context that never
reports blocks every merge, the admin's included.
"""

import sys
from collections.abc import Iterable, Iterator
from pathlib import Path

import hcl2
import yaml
from hcl2.utils import SerializationOptions

MODULE_CALL_FILE = Path("terraform/infrastructure/dungeon_studio_infrastructure.tf")
MODULE_CALL_NAME = "dungeon_studio_infrastructure"
MODULE_FILE = Path("terraform/modules/github_repository/main.tf")
WORKFLOWS = Path(".github/workflows")

PULL_REQUEST_FILTERS = {"branches", "branches-ignore", "paths", "paths-ignore"}
PULL_REQUEST_DEFAULT_TYPES = {"opened", "synchronize", "reopened"}


def load_hcl(path: Path) -> dict:
    with path.open() as f:
        return hcl2.load(f, serialization_options=SerializationOptions(strip_string_quotes=True))


def load_module_call() -> dict:
    modules = load_hcl(MODULE_CALL_FILE).get("module", [])
    return next(m[MODULE_CALL_NAME] for m in modules if MODULE_CALL_NAME in m)


def load_module_locals() -> dict:
    return {k: v for block in load_hcl(MODULE_FILE).get("locals", []) for k, v in block.items()}


def required_contexts(module_call: dict, module_locals: dict) -> set[str]:
    """Mirror main.tf's checks_refs: every context a checks ruleset requires."""
    checks = module_call.get("required_status_checks")
    if checks is None:
        return set()

    contexts = set(checks.get("contexts", []))
    if checks.get("ci_results_check", False):
        contexts.add(module_locals["ci_results_check"])
    if not module_call.get("legacy", {}).get("squash_only", False):
        contexts.add(module_locals["git_flow_source_check"])
    return contexts


def as_set(value: str | list[str]) -> set[str]:
    """GitHub Actions accepts a single string wherever it takes a list."""
    return {value} if isinstance(value, str) else set(value)


def triggers(workflow: dict) -> dict:
    """Map each event in on: to its filters."""
    # YAML 1.1 reads the bare key on as true.
    on = workflow.get("on", workflow.get(True)) or {}
    return on if isinstance(on, dict) else dict.fromkeys(as_set(on))


def skips_some_pull_requests(pull_request: dict) -> bool:
    types = as_set(pull_request.get("types", PULL_REQUEST_DEFAULT_TYPES))
    return bool(PULL_REQUEST_FILTERS & pull_request.keys()) or not PULL_REQUEST_DEFAULT_TYPES <= types


def runs_on_every_pull_request(workflow: dict) -> bool:
    on = triggers(workflow)
    return "pull_request" in on and not skips_some_pull_requests(on["pull_request"] or {})


def load_workflows() -> Iterator[dict]:
    for path in sorted([*WORKFLOWS.glob("*.yml"), *WORKFLOWS.glob("*.yaml")]):
        yield yaml.safe_load(path.read_text()) or {}


def reported_contexts(workflows: Iterable[dict]) -> set[str]:
    # A job without a name reports under its id.
    return {
        job.get("name", job_id)
        for workflow in workflows
        if runs_on_every_pull_request(workflow)
        for job_id, job in workflow.get("jobs", {}).items()
    }


def main() -> int:
    required = required_contexts(load_module_call(), load_module_locals())
    missing = sorted(required - reported_contexts(load_workflows()))
    for context in missing:
        print(
            f"{MODULE_CALL_FILE}: required check {context!r} matches no job in a workflow that runs on every pull request",
            file=sys.stderr,
        )
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
