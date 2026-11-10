---
name: review
description: Stage 5 of the AI SDLC. Final gate before implementation — have an independent reviewer agent review the intent, specs, design, and plan against each other and the codebase, resolve open questions with the user, and apply the approved fixes directly to those documents. Produces no new file.
argument-hint: "feature-slug"
disable-model-invocation: true
---

# /review — Pre-Implementation Review

You are running **stage 5 of 7** of the AI SDLC (`intent → specs → design → plan → review → build → verify`).
This is the **final check before any implementation starts**. Nothing gets built until these documents are right.
The review itself is done by the `reviewer` agent in a fresh context, because the agent that wrote the documents must not approve them. You relay its findings, settle the open questions with the user, and apply the approved fixes.
Be rigorous and specific. Don't praise, and don't pad.

## Input

**Arguments** (the text after the command) — the feature slug. If empty, list folders under `docs/ai-sdlc/` and ask which one.

## Preconditions

- `01-intent.md` through `04-plan.md` exist in `docs/ai-sdlc/<slug>/`. If any is missing, stop and point the user at the missing stage.
- This stage writes no document of its own: findings are presented in the conversation and fixes go straight into the existing documents.
- If `04-plan.md`'s `Decisions` section has an earlier `Review` entry, this is a re-review: read it, review everything afresh, and carry forward any findings still `Deferred` or `Rejected` so they aren't lost.

## 1. Check the mechanics

Run the traceability script that ships with this plugin on the feature folder and keep its output. The script is `scripts/trace.sh` in the plugin root, two directories above this `SKILL.md` (`<plugin>/skills/review/SKILL.md` → `<plugin>/scripts/trace.sh`). Resolve that to an absolute path first; the reviewer needs it too.

```bash
<plugin>/scripts/trace.sh docs/ai-sdlc/<slug>
```

## 2. Delegate the review

Dispatch the `reviewer` subagent (Claude Code names it `ai-sdlc:reviewer`). Give it the feature folder, the absolute path of the trace script, and the script's output. It reads every document, the project's source of truth, and the code, and returns a verdict, a findings table, traceability gaps, assumptions, and open questions.

- Don't review the documents yourself first, and don't soften, merge, or drop its findings. You may add a finding of your own if you notice one, and say it is yours.
- If the agent's report is missing a section, send it back to fill the gap.

## 3. Present findings

Don't edit any document yet, and don't write a review file. Present the reviewer's report to the user in the conversation:

1. **Verdict** (one line): `Ready` / `Ready with fixes` / `Not ready`.
   - **Ready** — no findings above Suggestion.
   - **Ready with fixes** — only Minor findings, or Majors whose fixes are clear and don't need decisions.
   - **Not ready** — any Blocker, or Majors that need decisions or rework of a stage.
2. **Findings table**, sorted by severity:

   | # | Severity | Doc § location | Finding | Proposed fix |
   |---|---|---|---|---|

   Severity is `Blocker` / `Major` / `Minor` / `Suggestion`. Keep each finding to one or two sentences and cite the exact file and section. Group by document if there are more than 15.
3. **Traceability gaps:** a short list of goal ↔ spec ↔ design ↔ plan mismatches.
4. **Assumptions I'll apply:** defaults from the report, listed so the user can veto them.
5. **Open questions:** only what the reviewer could not settle from the documents or the code. Ask them with the structured question tool (`AskQuestion` in Cursor, `AskUserQuestion` in Claude Code) in batches of up to 4, highest severity first. Each question gets 2–4 concrete options, with your recommended option first and marked "(Recommended)".

Then stop and wait for answers and for approval of the proposed fixes.

## 4. Apply

Once the user has answered and approved:

- Update only the affected documents (`01-intent.md` to `04-plan.md`), with minimal targeted edits that keep each document's structure and voice. Fix the same fact in every document that states it, so they stay consistent.
- Record the decisions in the `Decisions` section of the most relevant document, dated today.
- Keep each edited document at `Status: Approved` — the user approved these edits as part of this review.
- If the project's source-of-truth docs (`CLAUDE.md`, `AGENTS.md`, and the docs they point to) must change because of this feature, add those changes as plan tasks. Don't edit those files now unless the user says so.
- If a finding needs a stage redone rather than patched, say which (e.g. `/design <slug>`) instead of rewriting it here.
- Add one dated entry to the `Decisions` section of `04-plan.md`, headed `Review <today>`, with the final verdict and a line for every finding left `Deferred` or `Rejected` and why. Fixed findings need no entry beyond the decisions already recorded.
- Don't create `05-review.md` or any other new file.
- Don't commit.
- Finish with `git diff --stat docs/ai-sdlc/<slug>/`, a summary of what changed in five bullets or fewer, and any findings left unresolved (deferred or rejected) with the reason.

If the final verdict is **Ready**, summarize the plan's milestones and ask the user whether to begin implementing with `/build <slug>`.
