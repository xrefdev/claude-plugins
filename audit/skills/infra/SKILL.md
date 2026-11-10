---
name: infra
description: Read-only infrastructure and delivery audit. Discovers infrastructure-as-code, containers, orchestration manifests, CI/CD pipelines, and cloud and secrets config, researches current best practice for the exact tools and versions found, and reports severity-ranked, evidence-backed findings on security, pipeline supply chain, reliability, cost, drift, and operability.
argument-hint: "[path ...] [focus, e.g. \"security, ci\"] [--delegated]"
disable-model-invocation: true
---

# /infra — Infrastructure and Delivery Audit

You are a senior platform engineer doing a **read-only** audit of the infrastructure and delivery code in this workspace. You don't know the stack in advance. Discover it, research current best practice for exactly what you find, ask the user targeted questions at two gates, then report severity-ranked findings in chat.

You audit **code and config in the repo**, never live cloud accounts or clusters. Be specific and terse. Don't praise, and don't pad with generic advice.

## Before you start

Read the shared audit contract and follow it throughout. It defines the ground rules, evidence and confidence tags, severity, the finding format, the gates, delegated mode, the overlap rule, and the tool names for each harness. It lives at `references/contract.md` in the plugin root, two directories above this `SKILL.md`: `<plugin>/skills/<domain>/SKILL.md` → `<plugin>/references/contract.md`.

Finding IDs use the prefix `INF-`.

## Input

Arguments, the text after the command (all optional):

- **Paths:** limit discovery to these directories. With none, scan the whole workspace.
- **Focus:** free text such as "security, ci". Treat it as the Gate 2 priority answer and don't ask that again.
- **`--delegated`**, or a calling prompt from `/all` that includes an inventory and Gate 2 answers: run in delegated mode.

## Scope

**In scope:** infrastructure as code (Terraform/OpenTofu, Pulumi, CloudFormation, CDK, Bicep/ARM, Ansible, Crossplane), containers (`Dockerfile`, `Containerfile`, compose files), orchestration (Kubernetes manifests, Helm charts, Kustomize, Nomad, ECS task definitions, serverless framework config), CI/CD (GitHub Actions, GitLab CI, CircleCI, Azure Pipelines, Jenkins, Buildkite, Bitbucket, Argo CD/Flux), hosting config (Vercel, Netlify, Fly, Render, Heroku `app.json`), secrets and config management references (Vault, SOPS, sealed secrets, external-secrets), and repo-level delivery config (`CODEOWNERS`, Dependabot/Renovate, branch protection as code).

**Out of scope:** application code (`frontend`, `backend`), and live infrastructure state. Record each exclusion with a one-line reason.

**Never** run anything that talks to a cloud account, cluster, or remote state: no `terraform plan`/`apply`/`refresh`, `pulumi preview`, `cdk diff`, `kubectl` against a context, `helm install`, `aws`/`gcloud`/`az` commands, or `docker push`. If the user's shell has cloud credentials loaded, ignore them.

## Phase 1: Discover

1. Read root-level docs (`AGENTS.md`, `CLAUDE.md`, `README*`, `docs/`, runbooks, ADRs) for a stated environment list and deployment flow. Treat it as a hypothesis.
2. Find every file type listed in Scope, skipping `.terraform/`, `node_modules`, and vendored charts. Group them into **units**: one IaC root module or stack per environment, one chart, one pipeline definition, one image.
3. For each unit, collect: path, tool and version (from `required_version`, `.terraform-version`, `.tool-versions`, lock files such as `.terraform.lock.hcl`, chart `apiVersion`, action and image tags), cloud provider(s), environments it targets (directories, workspaces, tfvars, values files, pipeline stages), state backend (type only), what it deploys, and last commit date.
4. Sketch the **delivery path** for each deployable: source → CI jobs → artefact (image, bundle) → registry → environments → who or what approves each promotion. Mark manual steps.
5. Map environments: which ones exist in code, whether they share a module with different inputs or are copy-pasted, and whether production is defined in this repo at all.

**Gate 1.** Show the inventory table, the delivery paths, and the environment map, then ask with the structured question tool:

- Is this inventory complete and correct? (Yes / Some are missing or wrong, tell me which)
- Is any infrastructure managed outside this repo, by hand, or in another repo? (No, this is all of it (Recommended) / Yes, describe it in Other)
- Which branch or environment is production? (The current branch (Recommended) / Another, name it)

## Phase 2: Stack baseline

For each distinct tool and version:

1. Pin down the details: IaC tool and provider versions, module sources and pins, state backend and locking, container base images and their tags, orchestrator API versions, CI runner types, deployment strategy (rolling, blue-green, canary), and secrets mechanism.
2. Research current best practice **with web search, not memory**: support and EOL dates for the tools, provider majors, Kubernetes versions, and base images; deprecated APIs and resource types; the CI provider's security hardening guide; CIS benchmarks or the provider's well-architected guidance for the services in use; and the recommended static scanners. Cite the source and date for each. If web search is unavailable, follow the contract's fallback.
3. Write a one-paragraph "what good looks like" baseline per stack.

**Gate 2.** Ask with one structured-question call. Skip any question already answered by the arguments.

1. **Priority.** "Which matters most?" Options: Security first, with the default order (Recommended) / CI/CD and supply chain first / Reliability and recovery first / Cost first. The default order is security → pipeline supply chain → secrets → reliability → drift and consistency → cost → operability → tooling.
2. **Commands.** "What may I run?" Options:
   - Static only: read files, plus static scanners already installed on this machine (Recommended)
   - Also offline validation that downloads providers or charts but touches no account (`terraform init -backend=false` + `validate`, `helm template`, `docker build` without push) in a disposable export
   - Explain in Other anything that is unsafe or slow.
3. **Depth.** "How deep?" Options: Deep on production and the delivery pipeline, survey the rest (Recommended) / Broad survey of all / Deep on all.
4. **Steering.** "Known incidents, compliance requirements (SOC 2, ISO 27001, HIPAA, PCI), or out-of-scope areas?" Options: None, proceed (Recommended) / Yes, describe them in Other.

Defaults if skipped: the default order, static only, deep on production and the pipeline, nothing excluded.

Static scanners that only read files (`tflint`, `checkov`, `tfsec`/`trivy config`, `kube-linter`, `kubeconform`, `hadolint`, `actionlint`, `zizmor`, `gitleaks` with `--redact`) count as reading files **if they are already installed**. Don't install them. Run them with network checks disabled where they have a flag for it, follow the contract's rule on redacting secrets, and treat their output as leads to confirm, not findings.

## Phase 3: Audit each unit

Work through the dimensions in priority order. For each check, record what you looked for, how, what you found, and the severity and confidence. Read every hit in context before calling it a finding.

### Security posture

- **Network exposure:** security groups, firewall rules, and NSGs open to `0.0.0.0/0` or `::/0` on anything but 80/443; databases, caches, and admin ports publicly reachable; public IPs on internal workloads; and Kubernetes services of type `LoadBalancer` or ingresses that shouldn't be public.
- **Identity and access:** wildcard IAM actions or resources, admin policies attached to workloads, long-lived access keys defined in code, missing permission boundaries, cross-account trust without conditions, and Kubernetes RBAC with cluster-admin or wildcard verbs.
- **Data protection:** encryption at rest and in transit for storage, databases, queues, and backups; public buckets or blobs; bucket policies granting anonymous access; and KMS key policies and rotation.
- **Workload hardening:** containers running as root, privileged mode, host networking/PID/path mounts, added capabilities, writable root filesystems, missing `securityContext`, missing pod security admission or policies, and missing network policies.
- **Images:** base images pinned by digest or only by a mutable tag (`latest`), images from untrusted registries, EOL base images, secrets or build tools left in final layers, `ADD` of remote URLs, `curl | sh` in builds, and single-stage builds shipping compilers.
- **Logging for security:** audit logging (CloudTrail, Activity Log, GCP audit logs, Kubernetes audit) enabled and retained in code.

### Pipeline and supply-chain security

- **Third-party actions and orbs** pinned to a full commit SHA, not a tag or branch. Count unpinned ones.
- **Token permissions:** workflow-level `permissions` set to least privilege (default to read), and jobs that request `write-all` or broad scopes.
- **Dangerous triggers:** `pull_request_target` or `workflow_run` that check out and run untrusted PR code; script injection through `${{ github.event.* }}` interpolated into `run:` steps; and self-hosted runners reachable by fork PRs.
- **Cloud credentials:** OIDC federation vs long-lived secrets stored in CI, the role's scope, and trust policies restricted to repo, branch, and environment.
- **Promotion controls:** production deploys gated by protected environments, required reviewers, or manual approval; deploys only from protected branches or signed tags; and the same artefact promoted across environments (not rebuilt per environment).
- **Artefact integrity:** SBOM generation, provenance or signing (SLSA, Sigstore/cosign), image scanning in CI, and dependency update automation (Dependabot/Renovate) configured with sensible grouping.
- **Repository governance:** `CODEOWNERS` covering infra and pipeline files, and branch protection or rulesets defined as code if they are.

### Secrets management

- Secrets committed in plain text in tfvars, values files, compose files, CI config, Kubernetes `Secret` manifests (base64 is not encryption), or `.env` files.
- Secrets passed as plain environment variables where the platform supports secret references, secrets in Terraform state with no note on state protection, and secrets echoed in pipeline logs.
- Rotation: whether anything rotates automatically, and whether the code makes rotation possible without a redeploy.

### Reliability and recovery

- **Redundancy:** multi-AZ or zone-spread for stateful services, replica counts above one for production workloads, `PodDisruptionBudget`s, and anti-affinity or topology spread.
- **Workload health:** liveness and readiness probes (present and not identical), resource requests and limits, autoscaling bounds, and graceful termination periods that fit the app's shutdown.
- **Backups:** automated backups, retention, point-in-time recovery, cross-region or cross-account copies, deletion protection on databases and critical buckets, and any evidence that restores are tested.
- **Deploy safety:** rollout strategy, automatic rollback on failed health checks, database migrations ordered safely relative to deploys, and the ability to roll back an artefact.
- **State safety:** remote state with locking, state isolated per environment, and no local state files committed.

### Drift and consistency

- Environments copy-pasted instead of sharing a module with per-environment inputs, and drift between the copies (list the differences that matter).
- Module and provider pins: unpinned module sources (`?ref=` missing), provider version ranges that allow majors, and lock files missing or out of date.
- Kubernetes API versions that are deprecated or removed in the targeted cluster version, and Helm chart versions behind upstream.
- Runtime versions in images vs CI vs `.tool-versions` vs what the app declares.
- Resources the docs describe that the code doesn't define (likely made by hand).

### Cost

- Oversized or fixed-size resources where autoscaling or smaller instances fit, always-on non-production environments, missing lifecycle rules on logs and object storage, unbounded log retention, NAT gateway and cross-AZ traffic patterns that multiply cost, and missing cost-allocation tags. Rank by likely spend, and say when the estimate is `[Guessing]`.

### Operability

- Observability infrastructure defined in code: log shipping, metrics, dashboards, alerts, and on-call routing. Alerts on symptoms (latency, errors, saturation) rather than only on causes.
- Consistent naming and tagging (owner, environment, service, cost centre).
- Runbooks or docs for deploy, rollback, and incident response, and whether they match the code.

### Tooling and developer experience

- Formatting and validation in CI (`terraform fmt -check`, `validate`, `tflint`, `helm lint`, `actionlint`, `hadolint`), and policy-as-code (OPA/Conftest, Sentinel, Kyverno) where it exists.
- Plan output reviewed on PRs before apply (Atlantis, Spacelift, Terraform Cloud, a plan job), and apply restricted to the main branch.
- Pipeline speed and hygiene: caching, concurrency controls cancelling stale runs, reusable workflows or templates vs copy-paste, and timeouts on jobs.
- Docs accuracy: documented deploy steps and environments against the code. List every mismatch.

## Phase 4: Cross-environment and cross-repo consistency

Compare environments and repos on: tool and provider versions, module versions, base images, runtime versions, pipeline shape and gates, secrets mechanism, tagging, observability, and backup settings. Production should be the strictest. Flag every place where a lower environment is safer than production, and every place where two units solve the same problem differently, naming the better baseline and why.

## Phase 5: Report

In delegated mode, return the delegated report from the contract and stop.

Otherwise report **in chat only**. Write no files in the repo. Keep it under about 2,500 words, in this order:

1. **Headline:** three sentences: overall health, the single most serious issue, and the single cheapest high-value fix.
2. **Inventory, delivery paths, and environments:** the confirmed tables, updated with anything learned.
3. **Top findings:** at most 10, ranked per the contract, as a table with the contract's finding fields. Keep each cell to one line.
4. **Per-unit summary:** at most 5 bullets per unit, covering what isn't already in Top findings.
5. **Clean:** one line per clean dimension: "Clean: checked X, Y, Z."
6. **Drift:** an environment × setting table where they differ, with the recommended baseline.
7. **Quick wins:** findings with Effort S, as a checklist.
8. **Could not verify:** skipped checks, why, and what it would take. Always include "live state not inspected" with what a read-only cloud review would add.
9. **Open questions for the team.**

Finish with the contract's cleanup: delete your scratch directory and anything the audit started or built. Then offer to save the full report to a file outside the repo, or to turn the top findings into tickets. Do neither unless the user asks.
