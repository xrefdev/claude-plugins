---
name: verify
description: Stage 7 of the AI SDLC. Have an independent verifier agent check the built feature against the plan, requirements, and intent goals — running the real tests, checks, and app — then record the result in the plan. Fixes nothing itself.
argument-hint: "feature-slug"
disable-model-invocation: true
---

# /verify — Verify the Result

You are running **stage 7 of 7** of the AI SDLC (`intent → specs → design → plan → review → build → verify`).
This is the **final check after implementation**. The check is done by the `verifier` agent in a fresh context, because whoever built the feature must not be the one to say it works. You relay its results and record them.
Be rigorous and specific. Don't praise, and don't pad.

## Input

**Arguments** (the text after the command) — the feature slug. If empty, list folders under `docs/ai-sdlc/` and ask which one.

## Preconditions

- `01-intent.md` to `04-plan.md` exist in `docs/ai-sdlc/<slug>/`. If any is missing, stop and point the user at the missing stage.
- Every task in `04-plan.md` is checked (`- [x]`). If any isn't, list them and ask whether to verify anyway or to go back to `/build <slug>`.
- No `.current-task` file remains in the feature folder. If one does, a build was interrupted: say so and ask whether to continue it with `/build <slug>` or delete the marker.
- If `04-plan.md`'s `Decisions` section has an earlier `Verification` entry, this is a re-verification: read it and make sure the earlier failures are re-checked.

## 1. Run the verifier

Dispatch the `verifier` subagent (Claude Code names it `ai-sdlc:verifier`). Give it the feature folder. It runs the full suite, linters, every task's `Done when` check, the end-to-end task, and the running feature, and returns a verdict, a results table, requirement coverage, failures, and what it could not verify.

- Don't run the checks yourself first, and don't soften or drop its results. You may add something you noticed, and say it is yours.
- If the report is missing a section, send it back to fill the gap.

## 2. Present results

Show the user, in the conversation:

1. **Verdict** (one line): `Verified` / `Verified with gaps` / `Failed`.
2. **Results table** and **requirement coverage**, as the verifier returned them.
3. **Failures**, each with expected versus actual behaviour.
4. **Not verified**, with why, and what the user should check by hand.

## 3. Record and hand off

- Add one dated entry to the `Decisions` section of `04-plan.md`, headed `Verification <today>`, with the verdict, a line for each failure, and a line for each item left `Not verified`. This is the only edit this stage makes.
- Don't fix anything yourself. For each failure, offer to fix it with `/build <slug>` in bug-fix mode: a failing test first, then the fix. Then run `/verify <slug>` again.
- Don't commit.
- If the verdict is `Verified` or `Verified with gaps`, tell the user the feature is ready for their own review and a pull request, and list the gaps.
- Finish with `git diff --stat docs/ai-sdlc/<slug>/`.
