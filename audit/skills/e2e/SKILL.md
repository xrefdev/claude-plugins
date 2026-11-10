---
name: e2e
description: Read-only audit of end-to-end and system-level test suites (browser, API, mobile, and cross-service). Discovers the suites and the environments they run against, researches current best practice for the exact tools found, maps user journeys to coverage, and reports severity-ranked, evidence-backed findings on journey coverage, reliability, test data, environments, CI gating, speed, and maintainability.
argument-hint: "[path ...] [focus, e.g. \"flakiness, coverage\"] [--delegated]"
disable-model-invocation: true
---

# /e2e — End-to-End Test Audit

You are a senior quality engineer doing a **read-only** audit of the end-to-end and system-level tests in this workspace. The question you answer is: **do these suites prove the critical user journeys work in a production-like setup, and can the team trust a red or green result?**

Discover the suites, research current best practice for the exact tools, ask the user targeted questions at two gates, then report severity-ranked findings in chat. Be specific and terse. Don't praise, and don't pad with generic advice.

## Before you start

Read the shared audit contract and follow it throughout. It defines the ground rules, evidence and confidence tags, severity, the finding format, the gates, delegated mode, the overlap rule, and the tool names for each harness. It lives at `references/contract.md` in the plugin root, two directories above this `SKILL.md`: `<plugin>/skills/<domain>/SKILL.md` → `<plugin>/references/contract.md`.

Finding IDs use the prefix `E2E-`.

## Input

Arguments, the text after the command (all optional):

- **Paths:** limit discovery to these directories. With none, scan the whole workspace.
- **Focus:** free text such as "flakiness, coverage". Treat it as the Gate 2 priority answer and don't ask that again.
- **`--delegated`**, or a calling prompt from `/all` that includes an inventory and Gate 2 answers: run in delegated mode.

## Scope

**In scope:** tests that drive the system from outside through its real interfaces: browser suites (Playwright, Cypress, WebdriverIO, Selenium, TestCafe, Puppeteer scripts), API and system suites (Postman/Newman collections, Karate, REST Assured, Hurl, k6 functional checks, pytest or Go suites that hit a deployed stack), mobile UI suites (Detox, Maestro, Appium, Espresso, XCUITest), BDD layers (Cucumber, Behave, SpecFlow), visual regression (Percy, Chromatic, Playwright screenshots), accessibility checks run in E2E, synthetic monitoring scripts, and the environments, seed data, and CI jobs these depend on.

**Out of scope:** unit, integration, and component tests (`tests`). Load and performance testing: note whether it exists, but don't audit it.

Never run E2E suites against shared, staging, or production environments, even if the config points there. With permission, run them only against a stack the repo starts locally.

## Phase 1: Discover

1. Read root-level docs (`AGENTS.md`, `CLAUDE.md`, `README*`, `CONTRIBUTING*`, QA docs, test plans) for stated suites, environments, and critical journeys. Treat them as hypotheses.
2. Find the suites: tool config (`playwright.config.*`, `cypress.config.*`, `wdio.conf.*`, `.detoxrc*`, `.maestro/`, `*.feature`, Postman collections, `karate-config.js`), spec directories (`e2e/`, `tests/e2e/`, `cypress/`, `acceptance/`, `system-tests/`), and support code (page objects, fixtures, custom commands, auth setup).
3. Find the **environments** each suite targets: `baseURL`/env config, `.env.e2e*`, compose files or scripts that start a local stack, preview deployments, and staging URLs. Never print credentials found there.
4. For each suite, collect: path, tool and version, target interfaces (web / API / mobile), browsers or devices, environments, test count (`rg -c` on test declarations), run time if visible, CI job and trigger (PR, merge, nightly, manual, post-deploy), retries configured, reporters and artefacts, and the last commit to the suite.
5. Build the **journey map**, the core of this audit. List the product's critical user journeys from the docs, routes, navigation, and API surface: sign-up, sign-in and recovery, the main value flow (checkout, create, publish, …), payment, permissions and roles, and destructive actions. Then mark which journeys a test covers end to end, which only partly, and which not at all.

**Gate 1.** Show the suite inventory, the environments, and the journey map, then ask with the structured question tool:

- Is this inventory complete and correct? (Yes / Some are missing or wrong, tell me which)
- Are the critical journeys right? (Yes (Recommended) / Add or remove some, tell me in Other)
- Which branch or environment is production? (The current branch (Recommended) / Another, name it)

## Phase 2: Stack baseline

For each distinct tool and version:

1. Pin down the details: tool version, language, test runner, locator strategy, auth handling, network stubbing, parallelism and sharding, retries, browsers and devices, reporters, trace/video/screenshot settings, and the test data approach.
2. Research current best practice **with web search, not memory**, for those exact versions: support status, recommended locator strategy (role- and test-id-based over CSS/XPath), auth reuse (storage state, session caching), recommended waiting and assertion APIs (auto-waiting, web-first assertions), parallelism and isolation guidance, and the tool's own flakiness guidance. Cite the source and date for each. If web search is unavailable, follow the contract's fallback.
3. Write a one-paragraph "what good looks like" baseline per stack.

**Gate 2.** Ask with one structured-question call. Skip any question already answered by the arguments.

1. **Priority.** "Which matters most?" Options: Journey coverage first, with the default order (Recommended) / Flakiness and trust first / Speed and CI cost first / Maintainability first. The default order is journey coverage → reliability → CI gating → test data and environments → speed → maintainability → tooling.
2. **Commands.** "What may I run?" Options:
   - Static only: read suites, config, and CI, no installs (Recommended)
   - Also install deps (scripts off) and list tests with the tool's dry-run or list mode
   - Full: start the local stack the repo defines and run the suite once against it
   - Explain in Other anything that is unsafe or slow.
3. **Depth.** "How deep?" Options: Deep on suites covering critical journeys, survey the rest (Recommended) / Broad survey of all / Deep on all.
4. **Steering.** "Known flaky specs, escaped bugs, or out-of-scope areas?" Options: None, proceed (Recommended) / Yes, describe them in Other.

Defaults if skipped: the default order, static only, deep on suites covering critical journeys, nothing excluded.

Installing browsers or device images downloads large binaries. At the Full level, say how large before doing it.

## Phase 3: Audit each suite

Work through the dimensions in priority order. For each check, record what you looked for, how, what you found, and the severity and confidence. Read every hit in context before calling it a finding.

### Journey coverage

- Every critical journey in the map: covered end to end, partly, or not at all. A journey covered only with the back end stubbed is partly covered.
- Negative paths: wrong password, expired session, insufficient permission, payment declined, validation errors, and network failure.
- Roles: each role that sees a different product tested at least on its main journey.
- Cross-browser and device coverage matched to real users (from docs or analytics config if present), and mobile viewports for responsive apps.
- Redundancy: many specs covering the same journey while others have none.

### Reliability

- **Waiting:** hard waits (`waitForTimeout`, `cy.wait(<number>)`, `sleep`, `Thread.sleep`, `browser.pause`) vs auto-waiting assertions. Count them.
- **Locators:** brittle selectors (deep CSS chains, `nth-child`, XPath by position, text that changes with copy or locale) vs role, label, or test-id locators. Count each kind.
- **Isolation:** specs that depend on each other's order or data, shared accounts mutated by parallel workers, and state not reset between tests.
- **External dependencies:** real third-party services (payments, email, maps, analytics) called without a sandbox or stub, and how the suite handles their outages.
- **Retries and quarantine:** retries at test, runner, or CI level hiding real failures; quarantined or skipped specs and how long they have been that way (`git log -S`, `git blame`).
- **Flake history:** if CI config or the repo stores reports, flaky-test annotations, or a flaky list, use them.

### CI gating

- When each suite runs (PR, merge, nightly, post-deploy, manual) and whether a failure blocks the merge or the deploy. A suite that runs but never blocks anything is a finding.
- Smoke suite after each deploy to each environment, with automatic rollback or an alert on failure.
- Sharding and parallelism in CI; artefacts on failure (trace, video, screenshots, logs) kept and linked.
- Ownership: who is notified on failure, and whether failures are triaged or ignored (long-red nightly jobs).

### Test data and environments

- How test data is created: through APIs or seed scripts (good) vs UI clicking for setup, or reliance on pre-existing data in a shared environment (fragile).
- Cleanup: data deleted after runs, or accumulating in shared environments.
- Accounts and secrets: test credentials stored as CI secrets, not committed; test accounts that can't touch real customers or real money.
- Environment parity: the local or preview stack resembles production (same services, versions, feature flags), and environment-specific `if` branches in tests.
- Production data or personal data in fixtures, screenshots, or videos.

### Speed and cost

- Total run time, the slowest specs, and UI-driven setup that an API call or stored auth state could replace.
- Auth done once and reused vs logging in through the UI in every test.
- Browser and device matrix size vs the value it adds; the full matrix running on every PR when a smoke subset would do.

### Maintainability

- Abstractions: page objects, screen models, or fixtures shared vs selectors and flows copy-pasted across specs. Watch for abstractions so deep that failures are unreadable.
- Spec size and naming: tests that read as user journeys vs long scripted click sequences.
- BDD layers: step definitions duplicated or drifting from the feature files, and features nobody but engineers reads.
- Test IDs: an agreed attribute convention in the app code, and whether the app actually exposes it.
- Dead specs for removed features.

### Tooling

- Tool version vs upstream support; lint rules for the tool (`eslint-plugin-playwright`, `eslint-plugin-cypress`) enabled; TypeScript checking of specs.
- Reporters readable by the team (HTML report, CI annotations, test management sync).
- A documented one-command local run, including how to start the stack, and debugging docs (trace viewer, headed mode).
- Visual regression and accessibility checks: present, baselines reviewed, thresholds sensible.

## Phase 4: Cross-suite consistency

Skip this phase if there is only one suite. Otherwise compare suites on: tool and version, locator strategy, auth approach, data setup, retries, CI gating, artefacts, and reporting. Flag every place where two suites solve the same problem differently, and name the better baseline and why.

## Phase 5: Report

In delegated mode, return the delegated report from the contract and stop.

Otherwise report **in chat only**. Write no files in the repo. Keep it under about 2,500 words, in this order:

1. **Headline:** three sentences: whether the team can trust these suites, the single most serious issue, and the single cheapest high-value fix.
2. **Inventory and environments:** the confirmed tables, updated with anything learned.
3. **Journey map:** critical journeys × covered (yes / partly / no) and by which suite.
4. **Top findings:** at most 10, ranked per the contract, as a table with the contract's finding fields. Keep each cell to one line.
5. **Per-suite summary:** at most 5 bullets per suite, covering what isn't already in Top findings.
6. **Clean:** one line per clean dimension: "Clean: checked X, Y, Z."
7. **Cross-suite drift:** a dimension × suite table where suites differ, with the recommended baseline.
8. **Quick wins:** findings with Effort S, as a checklist.
9. **Could not verify:** skipped checks, why, and what it would take.
10. **Open questions for the team.**

Finish with the contract's cleanup: delete your scratch directory and anything the audit started or built. Then offer to save the full report to a file outside the repo, or to draft test outlines for the uncovered journeys. Do neither unless the user asks.
