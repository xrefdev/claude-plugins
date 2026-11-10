#!/usr/bin/env bash
# Regression checks for the plugin itself. Run from anywhere: ai-sdlc/evals/run.sh
# Needs bash and jq. Exits 1 if any check fails.
set -u

plugin=$(cd "$(dirname "$0")/.." && pwd)
repo=$(dirname "$plugin")
failures=0
pass() { echo "ok   $*"; }
fail() { echo "FAIL $*"; failures=$((failures + 1)); }

# All four manifests (Claude Code and Cursor, plugin and marketplace) agree on the version.
pv=$(jq -r .version "$plugin/.claude-plugin/plugin.json")
for m in "$repo/.claude-plugin/marketplace.json" "$repo/.cursor-plugin/marketplace.json"; do
  mv=$(jq -r '.plugins[] | select(.name == "ai-sdlc") | .version' "$m")
  [ "$pv" = "$mv" ] && pass "$(basename "$(dirname "$m")")/marketplace.json is $pv" || fail "plugin.json is $pv but $m is $mv"
done
cv=$(jq -r .version "$plugin/.cursor-plugin/plugin.json")
[ "$pv" = "$cv" ] && pass ".cursor-plugin/plugin.json is $pv" || fail ".claude-plugin is $pv but .cursor-plugin is $cv"
grep -q "^## $pv\$" "$plugin/CHANGELOG.md" && pass "CHANGELOG has $pv" || fail "CHANGELOG.md has no entry for $pv"

# The Cursor manifest points at files that exist, and the Cursor hook config is well-formed.
for key in skills agents hooks; do
  p=$(jq -r ".$key" "$plugin/.cursor-plugin/plugin.json")
  [ -e "$plugin/$p" ] && pass "cursor manifest $key -> $p" || fail "cursor manifest $key points at missing $p"
done
hc=$(jq -r '.hooks.preToolUse[0].command' "$plugin/hooks/hooks-cursor.json")
[ -x "$plugin/$hc" ] && pass "cursor hook command is executable ($hc)" || fail "cursor hook command $hc is not executable"
[ "$(jq -r .version "$plugin/hooks/hooks-cursor.json")" = 1 ] && pass "hooks-cursor.json has version 1" || fail "hooks-cursor.json needs \"version\": 1"

# Skill bodies carry nothing harness-specific.
if grep -rqE 'CLAUDE_PLUGIN_ROOT|\$ARGUMENTS|AskUserQuestion tool|Agent tool' "$plugin/skills"; then
  fail "a skill body still references a Claude Code-only variable or tool"
else
  pass "skill bodies are harness-neutral"
fi

# Every skill and agent has valid frontmatter, and skill names match their folders.
for f in "$plugin"/skills/*/SKILL.md; do
  dir=$(basename "$(dirname "$f")")
  name=$(sed -n 's/^name: //p' "$f" | head -1)
  desc=$(sed -n 's/^description: //p' "$f" | head -1)
  [ "$name" = "$dir" ] && [ -n "$desc" ] && pass "skill $dir" || fail "skill $dir: name or description is wrong"
done
for f in "$plugin"/agents/*.md; do
  base=$(basename "$f" .md)
  name=$(sed -n 's/^name: //p' "$f" | head -1)
  desc=$(sed -n 's/^description: //p' "$f" | head -1)
  tools=$(sed -n 's/^tools: //p' "$f" | head -1)
  if [ "$name" = "$base" ] && [ -n "$desc" ] && [ -n "$tools" ]; then pass "agent $base"; else fail "agent $base: name, description, or tools is wrong"; fi
  if grep -qE '^tools:.*(Edit|Write|NotebookEdit)' "$f"; then fail "agent $base must be read-only"; fi
  grep -q '^readonly: true$' "$f" || fail "agent $base needs readonly: true for Cursor, which ignores tools:"
done

# trace.sh passes the good fixture and catches each broken one.
for d in "$plugin"/evals/fixtures/*/; do
  name=$(basename "$d")
  out=$("$plugin/scripts/trace.sh" "$d" 2>&1); code=$?
  if [ -f "$d/expect.txt" ]; then
    if [ "$code" = 1 ] && grep -qF -- "$(cat "$d/expect.txt")" <<<"$out"; then pass "trace catches $name"; else fail "trace on $name: expected '$(cat "$d/expect.txt")', got: $out"; fi
  else
    [ "$code" = 0 ] && pass "trace accepts $name" || fail "trace on $name: $out"
  fi
done

# guard.sh behaviour.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/docs/ai-sdlc/f" "$tmp/src"
cat > "$tmp/docs/ai-sdlc/f/04-plan.md" <<'EOF'
- [ ] **T-1: Do it**
  - **Files:** `src/a.py`, `tests/test_a.py`
EOF
printf 'task=T-1\nmode=feature\ntests_locked=false\n' > "$tmp/docs/ai-sdlc/f/.current-task"

guard() { # option-value tool-input-json -> decision
  jq -n --arg cwd "$tmp" --argjson ti "$2" '{cwd: $cwd, tool_input: $ti}' |
    CLAUDE_PLUGIN_OPTION_GUARDRAILS=$1 "$plugin/hooks/guard.sh" |
    jq -r '.hookSpecificOutput.permissionDecision' | grep . || echo allow
}
expect() { [ "$3" = "$2" ] && pass "guard: $1" || fail "guard: $1 (expected $2, got $3)"; }

expect "off by default" allow "$(guard false "{\"file_path\":\"$tmp/src/other.py\",\"content\":\"x\"}")"
expect "allows a listed file" allow "$(guard true "{\"file_path\":\"$tmp/src/a.py\",\"content\":\"x\"}")"
expect "asks about an unlisted file" ask "$(guard true "{\"file_path\":\"$tmp/src/other.py\",\"content\":\"x\"}")"
expect "asks before Approved" ask "$(guard true "{\"file_path\":\"$tmp/docs/ai-sdlc/f/02-specs.md\",\"old_string\":\"Status:** Draft\",\"new_string\":\"Status:** Approved\"}")"
expect "allows other doc edits" allow "$(guard true "{\"file_path\":\"$tmp/docs/ai-sdlc/f/02-specs.md\",\"old_string\":\"a\",\"new_string\":\"b\"}")"
printf 'task=T-1\nmode=bugfix\ntests_locked=true\n' > "$tmp/docs/ai-sdlc/f/.current-task"
expect "denies test edits when locked" deny "$(guard true "{\"file_path\":\"$tmp/tests/test_a.py\",\"content\":\"x\"}")"
expect "allows code edits when locked" allow "$(guard true "{\"file_path\":\"$tmp/src/a.py\",\"content\":\"x\"}")"

# guard.sh under Cursor: payload as Cursor 3.29 sends it (hook_event_name preToolUse, workspace_roots, no cwd,
# whole file in content), flat output, "ask" downgraded to allow + agent_message, enabled by the marker file.
printf 'task=T-1\nmode=feature\ntests_locked=false\n' > "$tmp/docs/ai-sdlc/f/.current-task"
cguard() { # tool-input-json -> "permission|has_agent_message"
  jq -n --arg root "$tmp" --argjson ti "$1" \
    '{hook_event_name: "preToolUse", tool_name: "Write", workspace_roots: [$root], tool_input: $ti}' |
    (cd / && env -u CLAUDE_PLUGIN_OPTION_GUARDRAILS CURSOR_PROJECT_DIR="$tmp" "$plugin/hooks/guard.sh") |
    jq -r '[(.permission // "allow"), (if .agent_message then "msg" else "nomsg" end)] | join("|")' | grep . || echo "allow|nomsg"
}
expect "cursor: off without marker or option" "allow|nomsg" "$(cguard "{\"file_path\":\"$tmp/src/other.py\",\"content\":\"x\"}")"
touch "$tmp/docs/ai-sdlc/.guardrails"
expect "cursor: marker enables; listed file allowed" "allow|nomsg" "$(cguard "{\"file_path\":\"$tmp/src/a.py\",\"content\":\"x\"}")"
expect "cursor: unlisted file -> allow with nudge" "allow|msg" "$(cguard "{\"file_path\":\"$tmp/src/other.py\",\"content\":\"x\"}")"
printf -- '- **Status:** Draft\n' > "$tmp/docs/ai-sdlc/f/02-specs.md"
expect "cursor: Approved flip -> allow with nudge" "allow|msg" "$(cguard "{\"file_path\":\"$tmp/docs/ai-sdlc/f/02-specs.md\",\"content\":\"- **Status:** Approved\\n\"}")"
expect "cursor: other doc edit silent" "allow|nomsg" "$(cguard "{\"file_path\":\"$tmp/docs/ai-sdlc/f/02-specs.md\",\"content\":\"- **Status:** Draft\\nmore\\n\"}")"
printf 'task=T-1\nmode=bugfix\ntests_locked=true\n' > "$tmp/docs/ai-sdlc/f/.current-task"
expect "cursor: denies test edits when locked" "deny|msg" "$(cguard "{\"file_path\":\"$tmp/tests/test_a.py\",\"content\":\"x\"}")"
rm -f "$tmp/docs/ai-sdlc/.guardrails"

echo
[ "$failures" = 0 ] && echo "all checks passed" || echo "$failures check(s) failed"
exit "$((failures > 0))"
