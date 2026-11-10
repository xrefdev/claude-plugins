# Dual-harness: make ai-sdlc and audit load in Cursor as well as Claude Code

Branch: `feature/cursor`. One repo, both harnesses: `.claude-plugin/` and `.cursor-plugin/` side by side, `skills/` and `agents/` shared verbatim, per-harness hook config.

## Facts established (Phase 0, Cursor 3.29.15)

- `preToolUse` sees both `Write` and `StrReplace` as `tool_name: "Write"` with `tool_input.file_path` and the **full new file content** in `tool_input.content`. No `old_string`/`new_string`. Matcher: `Write`.
- Edit payloads carry no `cwd`; the project root is `workspace_roots[0]` and `$CURSOR_PROJECT_DIR`. `guard.sh`'s `$PWD` fallback is wrong for a plugin hook (PWD is the plugin dir).
- Hook output `{"permission":"allow"}` flat form works. Docs: `ask` is accepted but not enforced for `preToolUse`; `deny` and exit code 2 are enforced.
- Cursor does not template `${CLAUDE_PLUGIN_ROOT}` or `$ARGUMENTS` into skill bodies. No `userConfig` → env var. `tools:` on agents is ignored; `readonly: true` is the documented restriction. Skills are flat `/name`, no plugin namespace.

## Tasks

- [x] **T-0 Probe** — capture real hook payload; remove probe.
- [x] **T-1 Harness-neutral skill bodies** — replace `${CLAUDE_PLUGIN_ROOT}`, `$ARGUMENTS`, `AskUserQuestion`, `Agent tool`, `Bash`, namespaced agent and command names in all 14 `SKILL.md` + `contract.md`. Add a Tools section to `contract.md`.
- [x] **T-2 Agents** — add `readonly: true`; neutral wording for shell; keep `tools:` for Claude Code.
- [x] **T-3 Manifests** — root `.cursor-plugin/marketplace.json`; per-plugin `.cursor-plugin/plugin.json`; version check in `evals/run.sh`.
- [x] **T-4 Hooks** — `hooks/hooks-cursor.json`; `guard.sh` emits flat output under Cursor, maps `ask` → `allow` + `agent_message`, resolves project root from `workspace_roots`/`CURSOR_PROJECT_DIR`, opt-in via `docs/ai-sdlc/.guardrails` marker as well as the Claude option; tests in `evals/run.sh`.
- [x] **T-5 Docs** — README Cursor install + degradations; plugin READMEs; CHANGELOGs; bump ai-sdlc 0.4.0, audit 0.3.0.
- [x] **T-6 Verify** — `evals/run.sh` green (37 checks); `claude plugin validate` passes for marketplace and both plugins. Cursor local-install smoke test still manual: copy into `~/.cursor/plugins/local/`, reload, run `/intent`, `/review`, `/all`.

## Deferred (not in scope)

- Renaming `review` if it collides with Cursor's built-in `/review` — needs a UI check after local install.
- Renaming the repo away from `claude-plugins`.
