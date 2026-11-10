---
name: intent
description: Stage 1 of the AI SDLC. Rigorously capture why a feature should exist, for whom, and how success will be measured — grounded in the real codebase and the project's invariants — before any requirements are written. Produces docs/ai-sdlc/FEATURE/01-intent.md.
argument-hint: "feature name or one-line idea"
disable-model-invocation: true
---

# /intent — Capture Intent

You are running **stage 1 of 7** of the AI SDLC (`intent → specs → design → plan → review → build → verify`).
Your job is to turn a rough idea into a clear, agreed, measurable statement of intent that every later stage traces back to.
Be rigorous and specific. Don't praise, and don't pad. Do **not** write requirements, architecture, or code here.

## Input

**Arguments** (the text after the command) — a feature name or short idea. If empty, ask the user what they want to build.

## 0. Set up

- Derive a feature slug (kebab-case, e.g. `user-invitations`). If the input is ambiguous, confirm it.
- If `docs/ai-sdlc/<slug>/01-intent.md` already exists, switch to **revise mode** (see the end of this file) instead of starting over.

## 1. Load context

- Read the project's own source of truth for product scope, architecture, and conventions — `CLAUDE.md`, `AGENTS.md`, `README.md`, and whichever docs they point to that this idea touches. Treat the invariants they state as rules the intent must not break.
- Look for prior art: existing features, modules, or `docs/ai-sdlc/*` folders that already do part of this, overlap with it, or conflict with it.
- Spot-check the actual code for anything the idea assumes about the current state. Never assume something exists.

## 2. Interview

Work out the following with the user. Settle what you can from the context yourself and list it as an assumption; ask only what you can't.

- **Problem:** what is broken, missing, or painful, and the evidence for it (user reports, data, incidents, support load).
- **Users:** who has the problem — primary and secondary personas, and anyone affected indirectly (admins, support, ops).
- **Current workaround:** what people do today, and what it costs them.
- **Why now:** the trigger, and the cost of doing nothing.
- **Desired outcome:** what the world looks like when this is done.
- **Goals:** numbered `G-1`, `G-2`, … Each goal states one outcome and a **measurable success metric** (baseline → target, and how it will be measured).
- **Non-goals:** what this explicitly will not do, including tempting adjacent work.
- **Scope:** in scope and out of scope, at the level of user-facing capability.
- **Stakeholders:** who must agree, who will be consulted, who will be informed.
- **Constraints:** deadlines, budget, platforms, compliance, legal, and the project invariants that apply.
- **Dependencies:** other teams, services, or features this relies on.
- **Risks:** what could make this fail or cause harm (product, technical, legal, operational).
- **Open questions** that must be answered before specs.

Ask questions with the structured question tool (`AskQuestion` in Cursor, `AskUserQuestion` in Claude Code) in batches of up to 4, most important first. Each question gets 2–4 concrete options, with your recommended option first and marked "(Recommended)". Don't ask about things you can decide yourself with a sensible default; list those as **Assumptions I'll apply** so the user can veto them.

## 3. Self-check

Before presenting, verify and fix:

- Every goal has a measurable metric with a baseline and target, or an explicit note on how the baseline will be established.
- Goals describe outcomes, not solutions. No UI, schema, endpoint, or technology choices have slipped in.
- Non-goals are explicit, and no goal contradicts a non-goal.
- Nothing conflicts with the project's invariants or with an existing feature; if something does, it is called out as a risk or open question.
- Every claim about the current system was checked against the code or docs.

## Template

Template mode: **${user_config.template_mode}** (if this shows a `${user_config...}` placeholder or anything other than `guide` or `strict`, the option hasn't been set: use `guide`).

Read [templates/intent.md](templates/intent.md) before writing, in either mode.

- **guide** — use the template as a starting point. Add, merge, reorder, or leave out sections to suit the feature, but always keep:
  - the header lines (`Slug`, `Status`, `Date`, `Source of truth consulted`)
  - the goals table, with `G-n` IDs and a measurable metric for each goal
  - the non-goals
  - the `Decisions` section
- **strict** — follow the template exactly: every section, in order, with its headings, tables, and ID formats. Where a section doesn't apply, keep the heading and write "Not applicable — <reason>".

## 4. Write and present

- Write `docs/ai-sdlc/<slug>/01-intent.md` following the Template section above, with `Status: Draft`.
- Present: a two-line summary, the goals with their metrics, the assumptions applied, and any remaining open questions (asked via the structured question tool as above).
- Revise until the user approves. Then set `Status: Approved` and today's date.
- Don't commit. Finish with `git diff --stat docs/ai-sdlc/<slug>/`.

## Exit criteria

- Problem, users, goals with measurable metrics, non-goals, and scope are all filled in.
- No open question remains that would block specs.
- The user has explicitly approved the intent.

When done, tell the user the next step is `/specs <slug>`.

## Revise mode

When `01-intent.md` already exists:

- Read it and ask what has changed and why.
- Make minimal, targeted edits that keep its structure and voice. Keep goal IDs stable; retire a goal by marking it `Withdrawn` rather than renumbering.
- Record the change in its `Decisions` section, dated today.
- Set `Status: Draft` until the user re-approves.
- List any later documents (`02-specs.md` onward) that state the changed facts, and tell the user which stages to re-run. Don't edit them here.
