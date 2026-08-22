<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# 0. Record architecture decisions

## Status

Proposed

## Context

Decisions here outlive the pull requests that make them, and nothing
in the repository records why they went the way they did. The code
shows what a decision produced, git shows when it changed and who
changed it, and the issue tracker shows what was asked for. None of
them records the alternatives, or what the chosen option cost.

A reader without that cannot tell a weighed decision from a default.
Settled questions get reopened, and deliberate trade-offs get undone by
someone who never knew they were trade-offs.

## Decision

We will record architecturally significant decisions as Architecture
Decision Records under `docs/adr/`, in the format Michael Nygard
describes.

Each record is `NNNN-kebab-title.md`, numbered from this one and never
renumbered. A record is immutable once accepted. Changing a decision
means writing a new record and marking the old one
`Superseded by NNNN`.

A decision earns a record when it is architecturally significant and
hard to reverse: it locks in a vendor or dependency, sets a precedent
later work follows, or picks between alternatives a reader would
otherwise have to re-evaluate. Everything else belongs in a commit
message.

## Consequences

The reasoning behind a standing decision sits beside the decision, so
a reader reaches it without excavating git history or the tracker.

The product monorepo records this class of decision as numbered
explanation documents under `docs/explanation/`, so the organization
now has two shapes for the same kind of document. A reference that
crosses repositories has to say which it points at.

Recording a decision costs a document, so the practice decays if it is
applied to tactical choices.

## References

- [Documenting Architecture Decisions][nygard], Michael Nygard.

[nygard]: https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions
