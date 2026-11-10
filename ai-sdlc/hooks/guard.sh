#!/usr/bin/env bash
# ai-sdlc guardrails, run before a file edit (Claude Code: Edit/Write/MultiEdit; Cursor: Write). Off unless enabled.
#   1. Asks before a stage document is set to "Status: Approved".
#   2. While a build task is active, asks before editing a file the task doesn't list.
#   3. While a bug-fix task has its tests locked, denies edits to test files.
#
# Enable with either:
#   - the "guardrails" plugin option (Claude Code), or
#   - a marker file docs/ai-sdlc/.guardrails in the project (any harness).
#
# Harness differences handled here:
#   - Claude Code sends hook_event_name "PreToolUse" and reads hookSpecificOutput.permissionDecision (allow|deny|ask).
#   - Cursor sends "preToolUse" and reads a flat {permission, user_message, agent_message}. Cursor does not
#     enforce "ask" for preToolUse, so an ask becomes allow plus an agent_message that states the condition.
#   - Cursor's Write payload carries the whole new file in tool_input.content and no cwd; the project root is
#     workspace_roots[0] or $CURSOR_PROJECT_DIR.
set -u

command -v jq >/dev/null 2>&1 || exit 0
input=$(cat)

event=$(jq -r '.hook_event_name // empty' <<<"$input")
cursor=false
if [ -n "${CURSOR_PLUGIN_ROOT:-}" ] || [ "$event" = preToolUse ]; then cursor=true; fi

cwd=$(jq -r '.cwd // .workspace_roots[0] // empty' <<<"$input")
cwd=${cwd:-${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$PWD}}}

enabled="${CLAUDE_PLUGIN_OPTION_GUARDRAILS:-${CLAUDE_PLUGIN_OPTION_guardrails:-false}}"
[ "$enabled" = "true" ] || [ -f "$cwd/docs/ai-sdlc/.guardrails" ] || exit 0

file=$(jq -r '.tool_input.file_path // .tool_input.path // empty' <<<"$input")
[ -n "$file" ] || exit 0
rel=${file#"$cwd"/}

respond() { # decision reason
  if [ "$cursor" = true ]; then
    case "$1" in
      deny) jq -n --arg r "$2" '{permission: "deny", user_message: $r, agent_message: $r}' ;;
      ask)  jq -n --arg r "Guardrail: $2 This edit was allowed because Cursor cannot pause here. If the user has not confirmed it, revert the edit and ask them first." \
              '{permission: "allow", agent_message: $r}' ;;
    esac
  else
    jq -n --arg d "$1" --arg r "$2" \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  fi
  exit 0
}

approved='Status:\*\*[[:space:]]*Approved'

case "$rel" in
  docs/ai-sdlc/*/0[1-4]-*.md)
    new=$(jq -r '[.tool_input.content, .tool_input.new_string, (.tool_input.edits // [] | .[].new_string)] | map(select(. != null)) | join("\n")' <<<"$input")
    old=$(jq -r '[.tool_input.old_string, (.tool_input.edits // [] | .[].old_string)] | map(select(. != null)) | join("\n")' <<<"$input")
    if [ -z "$old" ] && [ -f "$file" ]; then old=$(cat "$file"); fi
    if grep -qE "$approved" <<<"$new" && ! grep -qE "$approved" <<<"$old"; then
      respond ask "This marks $rel as Approved. Approval is the user's sign-off, so confirm they have given it."
    fi
    exit 0
    ;;
  docs/*|.claude/*|.cursor/*)
    exit 0
    ;;
esac

marker=""
for m in "$cwd"/docs/ai-sdlc/*/.current-task; do
  [ -f "$m" ] && { marker=$m; break; }
done
[ -n "$marker" ] || exit 0

task=$(sed -n 's/^task=//p' "$marker" | head -1)
locked=$(sed -n 's/^tests_locked=//p' "$marker" | head -1)

case "$rel" in
  test/*|tests/*|*/test/*|*/tests/*|*/__tests__/*|*.test.*|*.spec.*|*_test.*|test_*|*/test_*)
    if [ "$locked" = "true" ]; then
      respond deny "Tests are locked for $task (bug fix: the failing test is written, now fix the code). If the test is wrong, tell the user and set tests_locked=false in $(basename "$(dirname "$marker")")/.current-task."
    fi
    ;;
esac

plan="$(dirname "$marker")/04-plan.md"
if [ -n "$task" ] && [ -f "$plan" ]; then
  block=$(awk -v t="**$task:" '
    index($0, t) { p = 1; next }
    p && (/^- \[[ x]\] \*\*T-/ || /^##/) { p = 0 }
    p
  ' "$plan")
  if ! grep -qF -- "$rel" <<<"$block"; then
    respond ask "$rel is not listed under $task in $(basename "$plan"). If this edit is needed, update the task in the plan in the same step."
  fi
fi
exit 0
