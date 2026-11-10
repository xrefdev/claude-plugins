---
name: specs
description: Stage 2 of the AI SDLC. Turn an approved intent into complete, testable functional and non-functional requirements — behaviour, data, states, permissions, interfaces, edge cases, and UX — each traced to a goal. Produces docs/ai-sdlc/FEATURE/02-specs.md.
argument-hint: "feature-slug"
disable-model-invocation: true
---

# /specs — Write Specifications

You are running **stage 2 of 7** of the AI SDLC (`intent → specs → design → plan → review → build → verify`).
Your job is to define **what** the system must do, precisely enough that every requirement can be tested and every goal is covered.
Be rigorous and specific. Don't praise, and don't pad. Do **not** choose architecture, schemas, or technologies here — describe behaviour and constraints, not implementation.

## Input

**Arguments** (the text after the command) — the feature slug. If empty, list folders under `docs/ai-sdlc/` and ask which one.

## Preconditions

- `docs/ai-sdlc/<slug>/01-intent.md` exists. If not, stop and tell the user to run `/intent` first.
- If the intent is not `Status: Approved`, warn the user and ask whether to continue.
- If `02-specs.md` already exists, switch to **revise mode** (see the end of this file).

## 1. Load context

- Read every document in `docs/ai-sdlc/<slug>/`.
- Read the project's source of truth — `CLAUDE.md`, `AGENTS.md`, and whichever docs they point to that this feature touches (domain model, API contracts, permissions, UX guidelines, testing). Treat their invariants as rules the specs must respect.
- Spot-check the actual code for current behaviour the specs will change or depend on (existing entities, roles, endpoints, screens). Never assume something exists.

## 2. Derive requirements

Work through every area below that the feature touches. Skip an area only if it genuinely doesn't apply, and say so in the document.

- **Functional requirements** — numbered `FR-1`, `FR-2`, … Each states one behaviour, traces to a goal (`G-n`), and has acceptance criteria in Given / When / Then form covering the happy path **and** the failure paths.
- **Data requirements** — the information the feature must create, read, update, or delete; what must be unique, required, or immutable; retention and deletion behaviour; what happens to existing data.
- **States and lifecycle** — every state an entity can be in, the allowed transitions and who/what triggers them, the illegal transitions, and what happens on cancellation, partial failure, retry, and duplicate requests (idempotency).
- **Permissions** — a matrix of which roles can perform which actions, including admins, support/staff tools, and API or automation access.
- **Interfaces** — user-facing and machine-facing behaviour: inputs, outputs, validation rules, error conditions and what the caller is told, notifications and events emitted, and whether any published contract changes.
- **External integrations** — third-party behaviour the feature relies on, and what happens when it is slow, down, or returns errors.
- **Edge cases** — concurrency and race conditions, limits and capacity, timezones and dates, zero/empty/maximum values, deleted or suspended owners, and anything specific to this domain.
- **UX requirements** — the flows, responsive behaviour, empty/loading/error states, accessibility, and copy that must exist.
- **Non-functional requirements** — numbered `NFR-1`, … with **measurable** targets: performance (latency percentiles, throughput), availability, security and PII handling, audit events, observability, compliance. Use the project's stated targets where they exist.
- **Glossary** — the canonical name for every domain term, so later documents use the same words.
- **Out of scope** — carried over from the intent's non-goals, plus anything newly excluded and why.

Ask questions with the structured question tool (`AskQuestion` in Cursor, `AskUserQuestion` in Claude Code) in batches of up to 4, highest impact first. Each question gets 2–4 concrete options, with your recommended option first and marked "(Recommended)". Don't ask about things you can decide yourself with a sensible default; list those as **Assumptions I'll apply** so the user can veto them.

## 3. Self-check

Before presenting, verify and fix:

- **Traceability:** every goal is covered by at least one requirement, and every requirement traces to a goal. Flag orphans in both directions.
- **Testability:** every acceptance criterion can be checked by a test or a measurement. Replace vague words ("fast", "easy", "secure") with numbers or observable behaviour.
- **Failure paths:** every FR says what happens when its input is invalid, the actor lacks permission, or a dependency fails.
- **No design leakage:** no tables, classes, frameworks, or endpoint paths unless they are an existing contract the feature must honour.
- **Consistency:** terms match the glossary everywhere; nothing contradicts the intent's non-goals or the project's invariants.
- **Current-state claims** were checked against the code.

## Template

Template mode: **${user_config.template_mode}** (if this shows a `${user_config...}` placeholder or anything other than `guide` or `strict`, the option hasn't been set: use `guide`).

Read [templates/specs.md](templates/specs.md) before writing, in either mode.

- **guide** — use the template as a starting point. Add, merge, reorder, or leave out sections to suit the feature, but always keep:
  - the header lines (`Slug`, `Status`, `Date`, `Intent`, `Source of truth consulted`)
  - the glossary
  - `FR-n` and `NFR-n` IDs, each with `Traces to` and acceptance criteria or a measurable target
  - the traceability table
  - the `Decisions` section
- **strict** — follow the template exactly: every section, in order, with its headings, tables, and ID formats. Where a section doesn't apply, keep the heading and write "Not applicable — <reason>".

## 4. Write and present

- Write `docs/ai-sdlc/<slug>/02-specs.md` following the Template section above, with `Status: Draft`.
- Present: the requirement count by area, the traceability table, the assumptions applied, and any remaining open questions (asked via the structured question tool as above).
- Revise until the user approves. Then set `Status: Approved` and today's date.
- Don't commit. Finish with `git diff --stat docs/ai-sdlc/<slug>/`.

## Exit criteria

- Every goal is covered and every requirement is traced.
- Every requirement is testable, including its failure paths.
- No open question remains that would block design.
- The user has explicitly approved the specs.

When done, tell the user the next step is `/design <slug>`.

## Revise mode

When `02-specs.md` already exists:

- Read it and ask what has changed and why (or re-derive from a revised intent).
- Make minimal, targeted edits that keep its structure and voice. Keep requirement IDs stable; retire a requirement by marking it `Withdrawn` rather than renumbering.
- Record the change in its `Decisions` section, dated today.
- Set `Status: Draft` until the user re-approves.
- List any later documents (`03-design.md` onward) that state the changed facts, and tell the user which stages to re-run. Don't edit them here.
