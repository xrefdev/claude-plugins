---
name: design
description: Stage 3 of the AI SDLC. Produce a rigorous technical design that satisfies every approved requirement — grounded in the real codebase and the project's invariants — covering architecture, data model, state machines, interfaces, integrations, permissions, non-functional concerns, rollout, and testing, with decisions recorded. Produces docs/ai-sdlc/FEATURE/03-design.md.
argument-hint: "feature-slug"
disable-model-invocation: true
---

# /design — Technical Design

You are running **stage 3 of 7** of the AI SDLC (`intent → specs → design → plan → review → build → verify`).
Your job is to decide **how** the system will satisfy every requirement, in enough detail that the plan can be written without making new design decisions.
Be rigorous and specific. Don't praise, and don't pad. Do **not** write implementation code here.

## Input

**Arguments** (the text after the command) — the feature slug. If empty, list folders under `docs/ai-sdlc/` and ask which one.

## Preconditions

- `01-intent.md` and `02-specs.md` exist in `docs/ai-sdlc/<slug>/`. If either is missing, stop and point the user at the missing stage.
- If the specs are not `Status: Approved`, warn the user and ask whether to continue.
- If `03-design.md` already exists, switch to **revise mode** (see the end of this file).

## 1. Load context

- Read every document in `docs/ai-sdlc/<slug>/`.
- Read the project's source of truth — `CLAUDE.md`, `AGENTS.md`, and whichever docs they point to that this feature touches (architecture, schema, API contracts, common patterns, testing, deployment). Treat their invariants as rules the design must not break.
- Study the code the feature will touch: the modules, models, services, endpoints, and UI it extends; the patterns and helpers already used for the same kind of problem; and how similar features were built. Open the files — never assume something exists or works a certain way.

## 2. Choose an approach

- Propose 2–3 viable approaches. For each: how it works, what it reuses, pros, cons, risks, and rough effort.
- Prefer the simplest approach that satisfies every requirement and fits existing patterns. Call out scope that could be cut or deferred.
- Ask the user to choose with the structured question tool (`AskQuestion` in Cursor, `AskUserQuestion` in Claude Code), with your recommended option first and marked "(Recommended)". Record the choice and the rejected alternatives as a decision.

## 3. Detail the design

Cover every area below that the feature touches. Skip an area only if it genuinely doesn't apply, and say so in the document. Name real files and modules, and mark anything new as **new**.

- **Overview and architecture** — a short summary and a Mermaid diagram of the components and how data flows between them.
- **Components** — each new or changed module, service, or UI piece: its responsibility, its file path, and what it reuses.
- **Data model** — entities, fields and types, constraints, indexes, relationships, deletion behaviour; migrations, their order and ownership, backfills or data migrations, and whether they are safe to run on live data.
- **State machines** — every state, transition, and illegal transition (Mermaid `stateDiagram` where it helps), and how cancellation, partial failure, retries, and idempotency are handled.
- **Interfaces** — endpoints, functions, events, or messages: request/response shapes, validation, error codes, versioning, and which published contract docs must change.
- **External integrations** — calls, webhooks, retries, timeouts, idempotency keys, and behaviour when the integration fails.
- **Permissions** — where each check in the specs' permission matrix is enforced.
- **Concurrency and consistency** — transactions, locking, race conditions, and how invariants hold under concurrent use.
- **Error handling** — failure modes and how each is surfaced, retried, or rolled back.
- **Security and privacy** — authn/authz, input validation, secrets, PII handling, and abuse cases.
- **Performance** — how each NFR target is met; N+1 risks, query plans, caching and invalidation.
- **Observability and audit** — logs, metrics, traces, alerts, and audit events.
- **UX implementation** — how flows, empty/loading/error states, responsive layouts, and accessibility are delivered with the project's UI patterns.
- **Rollout and rollback** — feature flags, migration and deploy order, backfill timing, how to undo each step safely.
- **Testing strategy** — which levels (unit, integration, end-to-end, contract, load) prove which requirements, and the fixtures or test data needed.
- **Source-of-truth impact** — changes this feature requires to `CLAUDE.md`, `AGENTS.md`, or the docs they point to.
- **Decisions** — ADR-style entries `D-1`, `D-2`, … (context, decision, consequences, alternatives rejected).
- **Risks** — technical and delivery risks with mitigations; unknowns that need a spike.

Ask questions with the structured question tool in batches of up to 4, highest impact first. Each question gets 2–4 concrete options, with your recommended option first and marked "(Recommended)". Don't ask about things you can decide yourself with a sensible default; list those as **Assumptions I'll apply** so the user can veto them.

## 4. Self-check

Before presenting, verify and fix:

- **Traceability:** every FR and NFR maps to at least one design element, and every design element serves a requirement. Flag orphans in both directions.
- **Completeness:** every state, edge case, permission, error, and integration failure in the specs has a design answer.
- **Consistency:** names, fields, and states match the specs' glossary; nothing contradicts the intent's non-goals, the specs, or the project's invariants.
- **Feasibility:** every file, module, helper, and API referenced exists in the code or is marked **new**; claims about current behaviour were checked.
- **Reversibility:** every migration and rollout step has a rollback.
- **No open design decisions** remain that the plan would have to make.

## Template

Template mode: **${user_config.template_mode}** (if this shows a `${user_config...}` placeholder or anything other than `guide` or `strict`, the option hasn't been set: use `guide`).

Read [templates/design.md](templates/design.md) before writing, in either mode.

- **guide** — use the template as a starting point. Add, merge, reorder, or leave out sections to suit the feature, but always keep:
  - the header lines (`Slug`, `Status`, `Date`, `Specs`, `Source of truth consulted`)
  - the components table, with real paths and new/changed marked
  - the requirement mapping table
  - `D-n` decisions with context, decision, alternatives, and consequences
- **strict** — follow the template exactly: every section, in order, with its headings, tables, and ID formats. Where a section doesn't apply, keep the heading and write "Not applicable — <reason>".

## 5. Write and present

- Write `docs/ai-sdlc/<slug>/03-design.md` following the Template section above, with `Status: Draft`.
- Present: the chosen approach in two lines, the key decisions, the requirement mapping, the main risks, the assumptions applied, and any remaining open questions (asked via the structured question tool as above).
- Revise until the user approves. Then set `Status: Approved` and today's date.
- Don't commit. Finish with `git diff --stat docs/ai-sdlc/<slug>/`.

## Exit criteria

- Every requirement maps to a design element, and every design element serves a requirement.
- Every referenced file and API is verified or marked **new**.
- Key decisions and rejected alternatives are recorded.
- The user has explicitly approved the design.

When done, tell the user the next step is `/plan <slug>`.

## Revise mode

When `03-design.md` already exists:

- Read it and ask what has changed and why (or re-derive from revised specs).
- Make minimal, targeted edits that keep its structure and voice. Keep decision IDs stable; supersede a decision with a new one that references it rather than rewriting history.
- Record the change in its `Decisions` section, dated today.
- Set `Status: Draft` until the user re-approves.
- List any later documents (`04-plan.md` onward) that state the changed facts, and tell the user which stages to re-run. Don't edit them here.
