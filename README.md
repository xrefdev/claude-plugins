# claude-plugins

A plugin marketplace for [Claude Code](https://docs.claude.com/en/docs/claude-code) and [Cursor](https://cursor.com/docs/plugins). Each plugin ships one set of skills and agents that both harnesses load.

## Plugins

| Plugin | Commands (Cursor / Claude Code) | Description |
|---|---|---|
| [ai-sdlc](ai-sdlc/) | `/intent`, `/specs`, `/design`, `/plan`, `/review`, `/build`, `/verify` — in Claude Code `/ai-sdlc:intent`, … | A staged, artifact-driven AI software development lifecycle. |
| [audit](audit/) | `/frontend`, `/backend`, `/infra`, `/tests`, `/e2e`, `/assets`, `/all` — in Claude Code `/audit:frontend`, … | Read-only, evidence-based codebase audits with severity-ranked findings. |

## Installation

### Claude Code

Add the marketplace once, then install any plugin from it as `<plugin>@ishahid`:

```
/plugin marketplace add ishahid/claude-plugins
/plugin install ai-sdlc@ishahid
/plugin install audit@ishahid
```

Or from your shell:

```bash
claude plugin marketplace add ishahid/claude-plugins
claude plugin install ai-sdlc@ishahid
claude plugin install audit@ishahid
```

For a whole team, add this to a project's `.claude/settings.json` so everyone who opens it is offered the marketplace and its plugins:

```json
{
  "extraKnownMarketplaces": {
    "ishahid": {
      "source": { "source": "github", "repo": "ishahid/claude-plugins" }
    }
  },
  "enabledPlugins": {
    "ai-sdlc@ishahid": true,
    "audit@ishahid": true
  }
}
```

Refresh the marketplace to pick up new versions, and uninstall what you no longer want:

```
/plugin marketplace update ishahid
/plugin uninstall ai-sdlc@ishahid
/plugin uninstall audit@ishahid
```

### Cursor

The repo carries a `.cursor-plugin/marketplace.json`, so in Cursor open **Settings → Customize → Plugins**, choose **From GitHub Repository**, enter `ishahid/claude-plugins`, and install `ai-sdlc` or `audit`. Teams can add the repo as a team marketplace in the dashboard instead. Cursor loads the same `skills/` and `agents/` that Claude Code does; the ai-sdlc guardrail hook ships in Cursor form as `ai-sdlc/hooks/hooks-cursor.json`.

Two things differ in Cursor. Commands are not namespaced (`/intent`, not `/ai-sdlc:intent`), and plugins have no per-user options, so ai-sdlc's `template_mode` is always `guide` and its guardrails are enabled with a marker file instead (see the [ai-sdlc README](ai-sdlc/README.md#configuration)).

## Repository layout

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json     # Claude Code marketplace "ishahid": lists every plugin below
├── .cursor-plugin/
│   └── marketplace.json     # The same list, in Cursor's format
├── ai-sdlc/                 # One folder per plugin
│   ├── .claude-plugin/plugin.json
│   ├── .cursor-plugin/plugin.json
│   ├── skills/
│   ├── agents/
│   ├── hooks/               # hooks.json (Claude Code), hooks-cursor.json (Cursor), guard.sh (both)
│   ├── scripts/
│   ├── evals/
│   ├── CHANGELOG.md
│   └── README.md
├── audit/
│   ├── .claude-plugin/plugin.json
│   ├── .cursor-plugin/plugin.json
│   ├── skills/              # frontend, backend, infra, tests, e2e, assets, all
│   ├── agents/              # auditor
│   ├── references/          # contract.md shared by every audit domain
│   ├── CHANGELOG.md
│   └── README.md
├── LICENSE
└── README.md
```

## Writing for both harnesses

Skills and agents are shared verbatim, so they must not depend on one harness:

- Name actions, not tools ("ask with the structured question tool", "dispatch the `reviewer` subagent"). Where a tool name is unavoidable, give both: `AskQuestion` in Cursor, `AskUserQuestion` in Claude Code.
- Refer to files inside the plugin relative to the skill's own `SKILL.md`, never through `${CLAUDE_PLUGIN_ROOT}`. Cursor does not expand it.
- Take input from "the text after the command", not `$ARGUMENTS`.
- Refer to commands by their short name (`/specs`); Claude Code users know their prefix.
- Mark read-only agents with both `tools:` (Claude Code) and `readonly: true` (Cursor).
- Hook scripts must handle both payloads and output shapes; `ai-sdlc/hooks/guard.sh` shows how.

## Adding a plugin

1. Create `<plugin-name>/.claude-plugin/plugin.json` and `<plugin-name>/.cursor-plugin/plugin.json`, each with at least a `name`. In the Cursor one, point `skills`, `agents`, and `hooks` at the folders explicitly.
2. Add components (`skills/`, `agents/`, `hooks/`, …) inside that folder.
3. Add an entry to `plugins` in both `.claude-plugin/marketplace.json` and `.cursor-plugin/marketplace.json` with `"source": "./<plugin-name>"`.
4. Validate:

   ```bash
   claude plugin validate .
   claude plugin validate ./<plugin-name>
   ```

5. Add a row to the table above.

## Development

Load one plugin from your working copy without installing it:

```bash
# Claude Code
claude --plugin-dir ./ai-sdlc

# Cursor: copy (not symlink) into the local plugins folder, then Developer: Reload Window
cp -R ./ai-sdlc ~/.cursor/plugins/local/ai-sdlc
```

A marketplace install of the same plugin name takes precedence over the local copy in Cursor, so uninstall it first when developing.

To release a new version of a plugin, bump `version` in all four places — `<plugin>/.claude-plugin/plugin.json`, `<plugin>/.cursor-plugin/plugin.json`, and the plugin's entry in both marketplace files — and add an entry to the plugin's `CHANGELOG.md`. `ai-sdlc/evals/run.sh` fails if they disagree.

## License

[MIT](LICENSE)
