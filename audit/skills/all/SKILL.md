---
name: all
description: Run every available audit domain (frontend, backend, infra, tests, e2e, assets, and any added later) as one read-only audit. Gates are asked once for all domains, each domain is audited in parallel by an independent agent, and the results are merged into one severity-ranked report.
argument-hint: "[domain ...] [--skip domain ...] [path ...]"
disable-model-invocation: true
---

# /all — Full Audit

You run several audit domains as **one** audit: discover once, ask the gate questions once, have one `auditor` subagent per domain do the work in parallel, then merge everything into a single severity-ranked report. You coordinate and synthesise. The domain skills define the checks.

Be specific and terse. Don't praise, and don't pad.

## Before you start

Locate the plugin root: it is two directories above this `SKILL.md` (`<plugin>/skills/all/SKILL.md` → `<plugin>`). Resolve it to an absolute path and keep it; you will pass paths under it to the auditors. Then read the shared contract at `<plugin>/references/contract.md` and list the directories in `<plugin>/skills/`.

**Every directory under `skills/` except `all` is a domain.** A domain that has no directory yet is not available. This is how new domains join `/all` without this file changing. The known domains, in report order:

| Domain | ID prefix | Covers |
|---|---|---|
| `frontend` | `FE` | browser code: apps, SSR, design systems |
| `backend` | `BE` | services, APIs, data access |
| `infra` | `INF` | IaC, containers, CI/CD, cloud config |
| `tests` | `TST` | test strategy and quality across the codebase |
| `e2e` | `E2E` | end-to-end and integration suites |
| `assets` | `AST` | images, fonts, media, static files |

A domain directory not listed here still runs. Take its ID prefix from its `SKILL.md`, or derive one from its name.

## Input

Arguments, the text after the command (all optional):

- **Domain names:** run only these.
- **`--skip <domain ...>`:** run every available domain except these.
- **Paths:** limit discovery to these directories.

If a named domain isn't available, say so in one line and continue with the rest.

## 1. Discover, once for all domains

Read each selected domain's `SKILL.md` and run its **Phase 1 (Discover)** yourself, inline. Discovery is cheap and needs the user, so it doesn't go to agents. Share the work where domains overlap: find repos and workspaces once, then apply each domain's markers.

A unit can belong to several domains (e.g. a Next.js app is both `frontend` and `backend`). List it under each domain, and note it in the overlap column.

Some domains build a map as part of discovery (the `backend` service map, the `infra` delivery paths, the `tests` risk map, the `e2e` journey map). Include each one.

**Gate 1.** Show one inventory with a section per domain, plus the combined excluded list, the maps, and a line per unavailable domain ("`infra`: not yet available"). Ask with the structured question tool:

- Is this inventory complete and correct?
- Which domains or units have priority?
- Which branch or environment is production?
- Then the domain-specific Gate 1 questions (e.g. infra managed outside the repo, the critical areas or journeys, where assets come from), merged where they overlap. Use a second call if there are more than 4.

## 2. Ask once

Build **one** Gate 2 from the domains' Gate 2 sections. Merge questions that ask the same thing (priority, commands, depth, steering) into one question that applies to every domain. A domain-specific question goes in only if its answer changes what that domain does. Respect the contract's limit of 4 questions per structured-question call. If more are left after merging, use a second call.

- **Priority:** offer the dimensions that the selected domains share (security, dependencies, tests, performance, tooling …).
- **Commands:** three levels mapped onto each domain's own options: static only (Recommended) / local checks (each domain's middle option: installs with scripts off, lint, unit tests, offline validation) / full (each domain's highest option). Apply the level to every domain unless the user names exceptions, and tell each auditor which of its own options that level means.

Defaults if skipped: each domain's own defaults. List them.

Don't run Phase 2 (stack baseline) yourself. Each auditor does it for its domain.

## 3. Dispatch

Dispatch one `auditor` subagent per selected domain (Claude Code names it `audit:auditor`), **all in a single message** so they run in parallel. Give each one:

- the domain name and the absolute path of its `SKILL.md` under the plugin root you resolved earlier
- the absolute path of the contract
- that domain's confirmed inventory, and every map it built in Phase 1, as corrected at Gate 1
- the Gate 2 answers, including any per-domain exceptions
- the list of the other domains running, for the overlap rule

If an agent's report is missing a delegated-report section or has findings without evidence, send it back once to fill the gap. If it fails outright, record that domain under "Could not verify" and continue with the others. Never fill in a domain's findings yourself.

## 4. Merge

- **Deduplicate.** The same root cause reported by two domains (e.g. a CVE in a package used by front end and back end, or Node version drift) becomes one finding. Keep the higher severity, list both IDs, and widen the scope.
- **Re-rank** all findings across domains per the contract: severity, then breadth, then confidence. Don't re-grade a domain's severity unless you have evidence it is wrong. If you do, say so.
- **Look for cross-domain issues** that no single domain could see, and add them as `ALL-<n>` findings with evidence. Examples: the front end and back end disagree on the API contract or the auth/token model; CI tests something the deploy pipeline doesn't build; the Node or language version differs between app code, CI, and container images.
- Keep each auditor's `Clean`, `Could not verify`, and `Open questions` sections, merged and deduplicated.

## 5. Report

Report **in chat only**. Write no files in the repo. Keep it under about 4,000 words, in this order:

1. **Headline:** three sentences: overall health, the single most serious issue across all domains, and the single cheapest high-value fix.
2. **Scorecard:** one row per domain: units audited, findings by severity (C/H/M/L), the top issue, and a one-word health rating (Good / Fair / Poor).
3. **Top findings:** at most 15, across all domains, ranked, as a table with the contract's finding fields. Keep each cell to one line.
4. **Cross-domain findings:** the `ALL-` findings.
5. **Per-domain summary:** at most 5 bullets per domain, covering what isn't already in Top findings. Include "Clean: checked X, Y, Z" lines.
6. **Drift:** the merged drift tables, with recommended baselines.
7. **Quick wins:** findings with Effort S, as a checklist.
8. **Could not verify:** per domain: what was skipped, why, and what it would take. Include unavailable domains.
9. **Open questions for the team.**

Finish by offering to save the full merged report, including all findings, to a file outside the repo, or to drill into one domain with its own `/<domain>` command. Do neither unless the user asks.
