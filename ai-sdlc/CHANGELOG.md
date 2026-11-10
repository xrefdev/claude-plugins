# Changelog

## 0.4.0

- Loads as a Cursor plugin as well as a Claude Code plugin: `.cursor-plugin/plugin.json` alongside `.claude-plugin/plugin.json`, with the same `skills/` and `agents/`.
- Skill bodies are harness-neutral. They no longer rely on `${CLAUDE_PLUGIN_ROOT}` or `$ARGUMENTS`, name actions instead of tools (`AskQuestion` in Cursor, `AskUserQuestion` in Claude Code), and refer to the stages as `/intent`, `/specs`, … (`/ai-sdlc:intent`, … in Claude Code).
- `review` and `verify` dispatch the `reviewer` and `verifier` subagents by short name; both agents now declare `readonly: true`, which is what Cursor enforces (it ignores `tools:`).
- Guardrails run in Cursor via `hooks/hooks-cursor.json`. In Cursor the two "ask" rules become an allow plus a message to the agent, because Cursor does not enforce `ask` before a tool call; the test-lock rule still denies. Guardrails can now also be enabled with a `docs/ai-sdlc/.guardrails` marker file, which works in both harnesses.
- `guard.sh` resolves the project root from the hook payload (`workspace_roots`) or `CURSOR_PROJECT_DIR`, not the hook process's working directory.
- `template_mode` is a Claude Code option only; Cursor always uses `guide`.

## 0.3.1

- Skill descriptions and argument hints no longer contain literal angle brackets (`<feature>`), which some loaders read as XML tags and rejected, so the skill never registered.

## 0.3.0

- New `build` stage: implements `04-plan.md` one task at a time (failing test first, then code, then the task's done-when check) and keeps the plan in sync with what was built.
- New `verify` stage: an independent `verifier` agent runs the tests, checks, and the app, and the result is recorded in the plan.
- `review` now delegates to a read-only `reviewer` agent in a fresh context, so the agent that wrote the documents no longer approves them.
- New `agents/` with `reviewer` and `verifier`, both read-only.
- New opt-in `guardrails` option and `hooks/`: ask before a document is marked Approved, ask before a build task edits an unlisted file, deny test edits while a bug fix has its tests locked.
- New `scripts/trace.sh`, a mechanical goal → requirement → design → plan traceability check that `review` runs first.
- New `evals/run.sh` with fixture features: checks manifest versions, skill and agent frontmatter, `trace.sh`, and the hooks.
- Pipeline is now `intent → specs → design → plan → review → build → verify`.
- Removed the unused `icon` field and `icon.png`: Claude Code does not read it.

## 0.2.1

- Set the plugin `displayName` to "ai-sdlc".

## 0.2.0

- `review` no longer writes `05-review.md`. It presents findings in the conversation, applies approved fixes to the existing documents, and logs deferred or rejected findings in a dated `Review` entry in the plan's `Decisions` section.

## 0.1.1

- Show the plugin as "AI SDLC" (added `displayName`).

## 0.1.0

- Initial release with five stages: `intent`, `specs`, `design`, `plan`, `review`.
- `template_mode` option: `guide` (default) or `strict`.
