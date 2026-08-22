<!-- SPDX-FileCopyrightText: 2026 Alex Brandt <alunduil@gmail.com> -->
<!-- SPDX-License-Identifier: MIT -->

# 0. Record architecture decisions

## Status

Proposed

## Context

This repository holds org-level infrastructure that no single product
owns, and its choices outlive the pull requests that make them. Before
changing anything, a later reader has to reconstruct which DNS provider
is authoritative, which credentials a layer runs with, and where the
boundary with a product falls. `terraform apply` runs out-of-band after
merge, so a reader who reconstructs wrong ships the mistake.

The product monorepo records this class of decision as numbered
explanation documents under `docs/explanation/`. That numbering is the
monorepo's own and does not extend to a second repository.

## Decision

We will record architecturally significant decisions as Architecture
Decision Records under `docs/adr/`, in the format Michael Nygard
describes: status, context, decision, consequences.

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

A reader can find the reasoning behind a standing decision without
reading git history or the issue tracker, and can tell a decision that
was weighed from one that was defaulted into.

The organization now has two shapes for the same kind of document, so
a reference that crosses repositories has to say which it points at.

Recording a decision costs a document, so the practice decays if it is
applied to tactical choices.

## References

- [Documenting Architecture Decisions][nygard], Michael Nygard.

[nygard]: https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions
