---
name: plan
description: Stage 4 of the AI SDLC. Break an approved design into small, dependency-ordered, test-first tasks — each naming its files, its failing test, and a concrete done check — with spikes, rollout, verification, and docs-sync covered. Produces docs/ai-sdlc/FEATURE/04-plan.md.
argument-hint: "feature-slug"
disable-model-invocation: true
---

# /plan — Implementation Plan

You are running **stage 4 of 7** of the AI SDLC (`intent → specs → design → plan → review → build → verify`).
Your job is to turn the design into a task list that an engineer — or Claude — can execute one red/green cycle at a time, without making new design decisions.
Be rigorous and specific. Don't praise, and don't pad. Do **not** start implementing.

## Input

**Arguments** (the text after the command) — the feature slug. If empty, list folders under `docs/ai-sdlc/` and ask which one.

## Preconditions

- `01-intent.md`, `02-specs.md`, and `03-design.md` exist in `docs/ai-sdlc/<slug>/`. If any is missing, stop and point the user at the missing stage.
- If the design is not `Status: Approved`, warn the user and ask whether to continue.
- If `04-plan.md` already exists, switch to **revise mode** (see the end of this file).

## 1. Load context

- Read every document in `docs/ai-sdlc/<slug>/`.
- Read the project's source of truth — `CLAUDE.md`, `AGENTS.md`, and whichever docs they point to on workflow, testing, migrations, and deployment. Follow their conventions for test layout, commands, branch and migration rules.
- Find the real commands the tasks will use: how to run a single test, the full suite, linters, type checks, migrations, and the dev server (from `package.json`, `Makefile`, `pyproject.toml`, CI config, or equivalent). Never invent a command.
- Open every file the design names, to confirm it exists and to see where changes will land. Never assume something exists.

## 2. Break down the work

- **Milestones** — group tasks into milestones that each leave the system working, deployable, and testable. Put risky or unknown work early.
- **Spikes first** — any unknown the design flagged gets a time-boxed spike task with a question to answer and a decision to record, before the tasks that depend on it.
- **Tasks** — numbered `T-1`, `T-2`, … Each task:
  - Is small enough for one red/green TDD cycle (roughly under an hour).
  - Names every file it creates or changes (mark new files **new**).
  - Traces to the requirements (`FR-n`, `NFR-n`) and design elements it delivers.
  - Lists the tasks it depends on.
  - States the **failing test to write first** — file, test name, and what it asserts.
  - Gives the implementation steps.
  - Ends with a **done when** check that is a real command and its expected result (e.g. `pytest tests/test_invites.py::test_expired_invite -q` passes), plus any manual check.
  - Flags risk, and whether it can run in parallel with other tasks (disjoint files, no shared dependency).
- **Ordering** — order by dependency, including across packages, services, or repos (e.g. shared core → app → API/admin; independent pieces separately). Data migrations come before the code that relies on them, and backfills are separate tasks.
- **Rollout tasks** — feature flags, migration and deploy order, backfill runs, and enabling the flag, each with its rollback.
- **Verification task** — a final end-to-end / smoke test of the feature against the intent's goals.
- **Docs-sync task** — updates to `CLAUDE.md`, `AGENTS.md`, contract docs, or other source-of-truth docs listed in the design's source-of-truth impact.

Ask questions with the structured question tool (`AskQuestion` in Cursor, `AskUserQuestion` in Claude Code) in batches of up to 4, highest impact first. Each question gets 2–4 concrete options, with your recommended option first and marked "(Recommended)". Don't ask about things you can decide yourself with a sensible default; list those as **Assumptions I'll apply** so the user can veto them.

## 3. Self-check

Before presenting, verify and fix:

- **Coverage:** every FR and NFR has at least one task, and every design element (component, migration, interface, integration, rollout step) is delivered by a task. Flag orphans in both directions.
- **Test-first:** every task that changes behaviour names its failing test; NFRs have a task that measures them.
- **Done checks:** every task ends with a runnable command that exists in this project, or an explicit manual check.
- **Ordering:** no task depends on one that comes after it; parallel tasks really touch disjoint files.
- **Size:** no task is larger than one red/green cycle; split any that are.
- **Consistency:** file paths, names, and fields match the design; no new design decisions were made — if one was needed, stop and send the user back to `/design`.
- **Completeness:** spikes, rollout, verification, and docs-sync tasks are present.

## Template

Template mode: **${user_config.template_mode}** (if this shows a `${user_config...}` placeholder or anything other than `guide` or `strict`, the option hasn't been set: use `guide`).

Read [templates/plan.md](templates/plan.md) before writing, in either mode.

- **guide** — use the template as a starting point. Add, merge, reorder, or leave out sections to suit the feature, but always keep:
  - the header lines (`Slug`, `Status`, `Date`, `Design`, `Source of truth consulted`)
  - the commands table
  - `T-n` tasks, each with files, what it delivers, dependencies, failing test first, and done when
  - the coverage table
  - the `Decisions` section
- **strict** — follow the template exactly: every section, in order, with its headings, tables, and ID formats. Where a section doesn't apply, keep the heading and write "Not applicable — <reason>".

## 4. Write and present

- Write `docs/ai-sdlc/<slug>/04-plan.md` following the Template section above, with `Status: Draft`.
- Present: the milestones with task counts, the critical path, tasks that can run in parallel, the main risks, the assumptions applied, and any remaining open questions (asked via the structured question tool as above).
- Revise until the user approves. Then set `Status: Approved` and today's date.
- Don't commit. Finish with `git diff --stat docs/ai-sdlc/<slug>/`.

## Exit criteria

- Every requirement and design element is covered by at least one task.
- Every task has a failing test (where it changes behaviour) and a runnable done check.
- Spikes, rollout, verification, and docs-sync tasks are present.
- The user has explicitly approved the plan.

When done, tell the user the next step is `/review <slug>` — the final check before implementation starts.

## Revise mode

When `04-plan.md` already exists:

- Read it and ask what has changed and why (or re-derive from a revised design).
- Make minimal, targeted edits that keep its structure and voice. Keep task IDs stable; retire a task by marking it `Withdrawn` rather than renumbering, and don't touch tasks already checked off unless asked.
- Record the change in its `Decisions` section, dated today.
- Set `Status: Draft` until the user re-approves, and tell the user to re-run `/review <slug>`.
