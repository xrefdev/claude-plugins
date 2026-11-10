# Changelog

## 0.3.0

- Loads as a Cursor plugin as well as a Claude Code plugin: `.cursor-plugin/plugin.json` alongside `.claude-plugin/plugin.json`, with the same `skills/`, `agents/`, and `references/`.
- Skill bodies are harness-neutral. They locate `references/contract.md` relative to their own `SKILL.md` instead of `${CLAUDE_PLUGIN_ROOT}`, take their arguments from the text after the command instead of `$ARGUMENTS`, and name actions instead of tools. The contract gains a "Tools and names per harness" table.
- `all` dispatches the `auditor` subagent by short name (`audit:auditor` in Claude Code) and resolves the plugin root from its own location before handing paths to the auditors.
- The `auditor` agent declares `readonly: true`, which is what Cursor enforces (it ignores `tools:`).
- Commands are referred to as `/all`, `/frontend`, … (`/audit:all`, … in Claude Code).

## 0.2.0

- New `backend` domain: security (injection, IDOR, tenancy, SSRF), data integrity (migrations, transactions, idempotency), reliability (timeouts, retries, queues), dependencies, API contracts, performance, observability, architecture, and tooling, with a service map.
- New `infra` domain: security posture, CI/CD supply chain (pinned actions, token permissions, dangerous triggers, OIDC), secrets, reliability and recovery, environment drift, cost, and operability. Audits code only and never touches cloud accounts or clusters.
- New `tests` domain: test suites in any language measured against a risk map built from critical areas, churn, and fix commits, plus effectiveness, determinism, coverage gating, speed, and CI integration.
- New `e2e` domain: browser, API, mobile, and system suites measured against a map of critical user journeys, plus reliability, CI gating, test data and environments, speed, and maintainability. Never runs against shared environments.
- New `assets` domain: delivery performance, licensing and provenance, SVG and metadata leaks, accessibility of media, caching, and repo hygiene including large blobs in git history.
- The contract now assigns each overlapping concern to one owner domain, and allows already-installed read-only scanners.
- `all` merges domain-specific Gate 1 questions and maps the command levels onto each domain's own options.

## 0.1.0

- Initial release.
- `frontend`: a read-only front-end audit for any stack. It discovers every unit that ships browser code, researches current best practice for the exact versions found, asks two batched gates, and reports severity-ranked, evidence-backed findings on security, dependencies and supply chain, accessibility, tests, performance, architecture, and tooling, plus cross-repo drift.
- `all`: runs every available domain as one audit. It discovers once, asks the gates once, has one `auditor` agent audit each domain in parallel, then deduplicates, re-ranks, and adds cross-domain findings.
- New `references/contract.md`: the shared ground rules, evidence and confidence tags, severity scale, finding format, gates, and delegated mode that every domain follows.
- New `auditor` agent: read-only, runs one domain in delegated mode.
- Commands that install, build, or test run only with permission, in a disposable `git archive` export, with lifecycle scripts off.
