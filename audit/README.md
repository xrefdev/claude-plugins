# audit

A plugin for Claude Code and Cursor for **read-only, evidence-based codebase audits**. Each audit discovers your stack instead of assuming it, checks it against current best practice for the exact versions it finds (researched on the web, with sources), asks you a few batched questions, and reports severity-ranked findings in chat. Every finding cites `path:line` or command output.

To install, see the [marketplace README](../README.md#installation). Commands are shown in their Cursor form; Claude Code prefixes them with the plugin name (`/audit:frontend`, `/audit:all`, …).

## Commands

| Command | Audits | Status |
|---|---|---|
| `/frontend [path …] [focus]` | Browser code: SPAs, SSR and meta-frameworks, server-rendered templates with bundles, web components, design systems, extensions | Available |
| `/backend [path …] [focus]` | Services, APIs, workers, data access, migrations, the server side of full-stack apps | Available |
| `/infra [path …] [focus]` | IaC, containers, Kubernetes/Helm, CI/CD pipelines, hosting and secrets config (code only, never live accounts) | Available |
| `/tests [path …] [focus]` | Unit, integration, and component suites in any language, measured against a risk and churn map | Available |
| `/e2e [path …] [focus]` | Browser, API, mobile, and system suites, measured against the critical user journeys | Available |
| `/assets [path …] [focus]` | Images, SVGs, fonts, media, documents, and committed binaries, including git history bloat | Available |
| `/all [domain …] [--skip domain …]` | Every available domain, merged into one report | Available |

## How an audit runs

1. **Discover:** find every repo, workspace package, and app in scope, including nested and multi-repo layouts. Out-of-scope code is listed with the reason.
2. **Gate 1:** you confirm the inventory, the priorities, and which branch is production.
3. **Baseline:** for each stack, research current best practice for that exact major version (support/EOL dates, deprecated APIs, recommended lint, test, and build settings) and write a short "what good looks like" paragraph to measure against.
4. **Gate 2:** you choose priorities, what it may run (static only by default), depth, and anything to steer toward or away from.
5. **Audit:** dimension by dimension in your priority order, then cross-repo consistency.
6. **Report:** in chat: headline, inventory, top findings, per-unit notes, clean dimensions, drift, quick wins, what couldn't be verified, and open questions.

`/all` runs discovery and both gates **once** for every domain, has an independent `auditor` agent audit each domain in parallel, then deduplicates, re-ranks, and adds cross-domain findings, such as a front end and back end that disagree on the auth model.

### Dimensions by domain

| Domain | Dimensions |
|---|---|
| frontend | security and privacy, dependencies and supply chain, accessibility, test quality, performance, architecture, tooling |
| backend | security, data integrity, reliability, dependencies, API contracts, performance, observability, architecture, tooling |
| infra | security posture, pipeline supply chain, secrets, reliability and recovery, drift, cost, operability, tooling |
| tests | risk gaps, effectiveness, determinism, coverage gating, speed, maintainability, CI integration |
| e2e | journey coverage, reliability, CI gating, test data and environments, speed, maintainability, tooling |
| assets | delivery performance, licensing, security and privacy, accessibility, caching, repo hygiene, tooling |

When several domains run under `/all`, each concern has one owner (for example, `tests` owns test quality and `assets` owns images and fonts), so findings aren't reported twice.

## Safety

Audits never edit, format, or commit your code. Without your approval at Gate 2 they only read files, run lockfile-only vulnerability audits, and search the web. If you allow installs, builds, or tests, they run in a disposable `git archive` export, never in your working tree, with lifecycle scripts disabled and the lockfile frozen. Committed secrets are reported by location, never printed.

## Severity and confidence

| Severity | Meaning |
|---|---|
| Critical | Exploitable now, exposes credentials or user data, or blocks shipping |
| High | Likely to cause an incident or security issue soon |
| Medium | A real, ongoing cost that isn't urgent |
| Low | Hygiene |

Every claim is tagged `[Certain]` (seen), `[Likely]` (strong inference), or `[Guessing]` (gap-filling).

## Adding a domain

1. Create `skills/<domain>/SKILL.md` with `disable-model-invocation: true`.
2. Have it read `references/contract.md` and follow its ground rules, finding format, gates, and delegated mode.
3. Give it `Phase 1: Discover` (ending in Gate 1), `Phase 2` (ending in Gate 2), its checks, and a report section that returns the delegated report in delegated mode.
4. Pick an ID prefix and add the domain to the table in `skills/all/SKILL.md`, and add any concern it owns to the overlap table in `references/contract.md`. `/all` picks up any new `skills/` directory automatically. The table only fixes report order and prefixes.
