---
name: build
description: Stage 6 of the AI SDLC. Implement an approved, reviewed plan one task at a time — failing test first, then the code, then the task's done-when check — keeping the plan in sync with what actually gets built. Updates docs/ai-sdlc/FEATURE/04-plan.md as tasks complete.
argument-hint: "feature-slug [T-n]"
disable-model-invocation: true
---

# /build — Implement the Plan

You are running **stage 6 of 7** of the AI SDLC (`intent → specs → design → plan → review → build → verify`).
Your job is to execute `04-plan.md` exactly: one task, one red/green cycle at a time, with evidence for each.
You are the author of this code, so you do not judge whether it is done: the plan's checks and the later `verify` stage do.
Be rigorous and specific. Don't praise, and don't pad.

## Input

**Arguments** (the text after the command) — the feature slug, optionally followed by a task ID (`T-n`) to run just that task. If the slug is empty, list folders under `docs/ai-sdlc/` and ask which one.

## Preconditions

- `01-intent.md` to `04-plan.md` exist in `docs/ai-sdlc/<slug>/` and are `Status: Approved`. If any is missing or unapproved, stop and point the user at the missing stage.
- `04-plan.md`'s `Decisions` section has a `Review` entry with a verdict of `Ready`, or `Ready with fixes` whose fixes were applied. If there is none, or the verdict was `Not ready`, stop and send the user to `/review <slug>`.
- Run `git status` and `git branch --show-current`. If the working tree has unrelated changes, say so and ask how to proceed. If you are on the repository's default branch, ask whether to create a feature branch first.
- Ask once, before starting: **commit after each task, or leave all changes uncommitted?** Default to uncommitted. Never push.

## 1. Pick the task

- Work through the plan's tasks in order. Start at the first unchecked task whose dependencies are all checked (`- [x]`), or at the task given in the arguments.
- Don't start a task whose dependencies aren't done. Run one task at a time even if the plan marks tasks as parallel.
- Before each task, read the files it names, so you edit what is really there.

## 2. Run the task

Create the task marker `docs/ai-sdlc/<slug>/.current-task` with these lines, and keep it up to date. The plugin's optional guardrail hooks read it.

```
task=T-n
mode=feature
tests_locked=false
```

**Spike tasks:** answer the question, record the answer in the plan's `Decisions` section, and check the task off. Write no production code.

**Feature tasks:**
1. Write the failing test the task names. Run it and confirm it fails for the right reason (the behaviour is missing, not a typo or import error).
2. Implement the change the steps describe.
3. Run the test until it passes, then the related suite.
4. Run the task's `Done when` command and read its output.

**Bug-fix tasks:** set `mode=bugfix`.
1. Write the failing test that reproduces the bug. Run it and confirm it fails for the right reason.
2. Set `tests_locked=true`. From now on, don't edit any test file.
3. Fix the code until the test passes, then run the related suite and the task's `Done when` command.
4. If the test itself turns out to be wrong, stop, set `tests_locked=false`, tell the user why, and wait for their go-ahead before changing it.

**Rollout tasks:** run the steps and the rollback check only when the task says so. Never run production deploys, migrations against shared data, or flag changes on your own; list the exact commands for the user instead.

## 3. Close the task

- Report the `Done when` command and its result. If it fails, fix the cause within the task. If three attempts fail, stop and tell the user what you tried.
- Check the task off in the plan (`- [x]`), in the same step as the code.
- **If what you built differs from the plan** — a file touched that the task doesn't list, a different approach, an added or skipped step — update the task in `04-plan.md` to match what was done, and add a dated line to its `Decisions` section saying what changed and why.
- **If you need a design decision the documents don't make**, or the work contradicts the spec or design, stop. Don't decide it yourself: tell the user and point them at `/design <slug>` or `/specs <slug>`.
- If the user chose to commit after each task, commit now with a message naming the task. Otherwise leave the changes in the working tree.
- Delete `.current-task` when the task is done.

Then go to the next task. After each milestone, run the plan's full-suite command and report the result before continuing.

## 4. Finish

When every task is checked:

- Run the plan's full test, lint, and type-check commands, and report the results.
- Make sure `.current-task` no longer exists.
- Finish with `git diff --stat`, a summary of what was built in five bullets or fewer, and anything deferred or left unchecked with the reason.
- Tell the user the next step is `/verify <slug>`, where an independent verifier checks the result. Don't declare the feature done yourself.
