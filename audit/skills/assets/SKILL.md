---
name: assets
description: Read-only audit of static assets (images, icons, SVGs, fonts, video, audio, documents, and other binaries) across the workspace. Discovers where assets live and how they are processed and served, researches current best practice for the exact pipeline found, and reports severity-ranked, evidence-backed findings on delivery performance, caching, licensing, accessibility, security and privacy, and repository hygiene.
argument-hint: "[path ...] [focus, e.g. \"performance, licensing\"] [--delegated]"
disable-model-invocation: true
---

# /assets — Static Asset Audit

You are a senior web-performance and build engineer doing a **read-only** audit of the static assets in this workspace and how they are produced, stored, and served. The questions you answer are: **are assets delivered fast, are we allowed to ship them, do they leak anything, and are they bloating the repo?**

Discover the assets and their pipeline, research current best practice, ask the user targeted questions at two gates, then report severity-ranked findings in chat. Be specific and terse. Don't praise, and don't pad with generic advice.

## Before you start

Read the shared audit contract and follow it throughout. It defines the ground rules, evidence and confidence tags, severity, the finding format, the gates, delegated mode, the overlap rule, and the tool names for each harness. It lives at `references/contract.md` in the plugin root, two directories above this `SKILL.md`: `<plugin>/skills/<domain>/SKILL.md` → `<plugin>/references/contract.md`.

Finding IDs use the prefix `AST-`.

## Input

Arguments, the text after the command (all optional):

- **Paths:** limit discovery to these directories. With none, scan the whole workspace.
- **Focus:** free text such as "performance, licensing". Treat it as the Gate 2 priority answer and don't ask that again.
- **`--delegated`**, or a calling prompt from `/all` that includes an inventory and Gate 2 answers: run in delegated mode.

## Scope

**In scope:** raster images, SVGs and icon sets, fonts, video and audio, PDFs and downloadable documents, favicons and app icons, web manifests, email templates' images, design-tool exports, and other committed binaries (archives, datasets, models). Also the pipeline around them: image and font processing in the build, asset hashing, CDN and caching config, `<img>`/`<picture>`/`<video>`/`@font-face` usage, and Git LFS config.

**Out of scope:** JavaScript and CSS bundle size (`frontend`), and server-side handling of user-uploaded files (`backend`), except where uploads are served back as static assets. When `frontend` is not running, give image and font loading in markup a full pass, since this domain owns it.

## Phase 1: Discover

1. Read root-level docs (`AGENTS.md`, `CLAUDE.md`, `README*`, `docs/`, design-system docs, brand guidelines) for stated asset conventions, sources, and licences. Treat them as hypotheses.
2. Find asset directories (`public/`, `static/`, `assets/`, `src/assets/`, `images/`, `fonts/`, `media/`, `wwwroot/`, `app/assets/`, `res/`), skipping build output and `node_modules`. Inventory by type with `git ls-files` and `file`, and sizes with `git ls-files -z | xargs -0 du -k` or `find -size`.
3. Find the **pipeline**: build-time image tools (`next/image`, `@nuxt/image`, `astro:assets`, `vite-imagetools`, `sharp`, `imagemin`, `svgo`, `responsive-loader`), font tools (`next/font`, `@fontsource/*`, `fontsource`, subsetting scripts, Google Fonts links), icon systems (sprite sheets, icon fonts, icon component libraries), image CDNs (Cloudinary, Imgix, Cloudflare Images, CloudFront), `.gitattributes` for LFS, and caching config (hosting config, CDN rules, framework headers config).
4. Find **history bloat**: the largest blobs ever committed, including deleted ones:

   ```bash
   git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk '$1=="blob"' | sort -k3 -nr | head -25
   ```

5. For each unit, collect: asset directories, counts and total size by type, the largest 10 files, the pipeline in use, the hosting and CDN, LFS usage, and repo size (`git count-objects -vH`).

**Gate 1.** Show the inventory by unit and type, the pipeline summary, and the largest files in the tree and in history, then ask with the structured question tool:

- Is this inventory complete and correct? (Yes / Some are missing or wrong, tell me which)
- Where do assets come from? (Mostly made in-house or by a design team (Recommended) / Mix of in-house, stock, and third-party, I'll describe it in Other)
- Which branch or environment is production? (The current branch (Recommended) / Another, name it)

## Phase 2: Pipeline baseline

1. Pin down the details: framework image and font components and their versions, processing libraries, output formats, responsive breakpoints, lazy-loading defaults, the CDN and its transformation features, and the caching headers configured.
2. Research current best practice **with web search, not memory**: current browser support for AVIF, WebP, variable fonts, and `font-display`; Core Web Vitals guidance on images and fonts (LCP image priority, `fetchpriority`, layout-shift prevention, preloading); the framework's image and font component docs for the exact version; and SVG optimisation and security guidance. Cite the source and date for each. If web search is unavailable, follow the contract's fallback.
3. Write a one-paragraph "what good looks like" baseline per unit.

**Gate 2.** Ask with one structured-question call. Skip any question already answered by the arguments.

1. **Priority.** "Which matters most?" Options: Delivery performance first, with the default order (Recommended) / Licensing and compliance first / Repo size and hygiene first / Accessibility first. The default order is delivery performance → licensing → security and privacy → accessibility → caching → repo hygiene → tooling.
2. **Commands.** "What may I run?" Options:
   - Static only: read files, git history, and metadata with tools already installed (`file`, `identify`, `exiftool`, `fc-scan`) (Recommended)
   - Also run the production build in a disposable export to measure processed output
   - Explain in Other anything that is unsafe or slow.
3. **Depth.** "How deep?" Options: Deep on user-facing apps, survey the rest (Recommended) / Broad survey of all / Deep on all.
4. **Steering.** "Known slow pages, licence concerns, or out-of-scope areas?" Options: None, proceed (Recommended) / Yes, describe them in Other.

Defaults if skipped: the default order, static only, deep on user-facing apps, nothing excluded.

## Phase 3: Audit each unit

Work through the dimensions in priority order. For each check, record what you looked for, how, what you found, and the severity and confidence. Confirm every hit in context before calling it a finding.

### Delivery performance

- **Oversized images:** raster files above about 200 KB, and images whose pixel dimensions (`identify`, or `file` output) are far larger than any size they are displayed at. List the worst offenders with sizes.
- **Formats:** photos as PNG, screenshots as JPEG with artefacts, no AVIF/WebP for large images, animated GIFs that should be video, and video without a compressed modern codec or a poster.
- **Responsive delivery:** `<img>` without `srcset`/`sizes` for large images, framework image components bypassed with raw `<img>`, and art direction missing where mobile crops matter.
- **Loading strategy:** the LCP image lazy-loaded, or lacking `fetchpriority="high"`/preload; below-the-fold images loaded eagerly; images and video without `width`/`height` or `aspect-ratio` (layout shift).
- **Fonts:** number of families, weights, and files loaded; no subsetting; legacy formats (TTF, EOT, WOFF) where WOFF2 is enough; missing `font-display`; no preload for critical fonts; fonts from third-party origins without `preconnect`; and icon fonts where SVG icons would be lighter and more accessible.
- **SVGs:** unoptimised SVGs (editor metadata, huge path data), large SVGs inlined in every page, and raster images embedded in SVGs as base64.
- **Inlining:** large data URIs in CSS or JS.

### Licensing and provenance

- **Fonts:** each font family's licence (OFL, Apache, commercial) and whether a licence file or source is recorded. Commercial fonts self-hosted without evidence of a web licence are at least High.
- **Icons and illustrations:** the icon sets used and their licences, and attribution requirements (CC BY) met where shown.
- **Stock and third-party media:** stock photos with watermark remnants or filenames from stock sites, images hot-linked from third-party domains, and media without a recorded source.
- **Brand assets:** third-party logos used outside their brand guidelines, if the repo contains such guidelines.
- Record unknown provenance as `[Guessing]` and put it under Open questions, not Top findings, unless there is evidence.

### Security and privacy

- **SVG risk:** SVGs containing `<script>`, event handler attributes, `<foreignObject>`, or external references, especially if users can upload SVGs that are served from the app's origin.
- **Metadata leaks:** photos with EXIF GPS coordinates, device serials, or author names (`exiftool -gps:all -a` on a sample, if installed, reporting only which fields are present, as the contract requires); PDFs and Office documents with author names, internal paths, comments, or tracked changes.
- **Sensitive content:** screenshots or images showing real customer data, internal dashboards, credentials, or tokens. Sample screenshots in docs and fixtures, and describe what you saw without reproducing it.
- **Hot-linked assets** from domains the team doesn't control, which can be swapped or tracked.

### Accessibility

- Meaningful images without useful `alt`; decorative images without empty `alt`; `alt` text that duplicates adjacent text or reads "image of".
- Inline SVG icons without `aria-hidden` or an accessible name; icon-only buttons without labels; icon fonts read aloud as letters.
- Video without captions, audio without transcripts, autoplaying media without controls or with sound, and animations without `prefers-reduced-motion` handling.
- Text baked into images (headings, banners) that should be live text.

### Caching and delivery

- Content-hashed filenames for build assets, and long-lived immutable caching on them; unhashed assets served with long cache lifetimes (stale after deploys) or with no caching.
- Compression for SVG, fonts, and other text-like assets; correct `Content-Type` and CORS headers for fonts.
- Image CDN or optimisation service used where the framework doesn't optimise, and cache keys that don't explode per request parameter.

### Repository hygiene

- Large binaries in the tree and in history (from Phase 1), and whether Git LFS or external storage should hold them. Large files deleted from the tree but still in history bloat every clone.
- Duplicates: identical files under different names (`git ls-files -s` hashes or `md5`), and the same asset at many slightly different sizes.
- Unused assets: files never referenced from code, templates, CSS, or content (search for each filename stem). Report the count and total size, plus the largest unused files.
- Source files that don't belong in the repo (PSD, Sketch, Figma exports, RAW photos, video masters) unless the team intends it.
- `.gitattributes` rules for binaries (`binary`, LFS filters) and LFS files actually tracked by LFS rather than committed as blobs.

### Tooling

- Optimisation automated in the build or CI (image processing, `svgo`, font subsetting) vs done by hand or not at all.
- Budgets or checks on asset size (Lighthouse CI, size-limit for assets, a CI check rejecting large binaries, pre-commit file-size hooks).
- A documented convention for where assets go, naming, formats, and how to add a new font or icon.

## Phase 4: Cross-repo consistency

Skip this phase if there is only one unit. Otherwise compare units on: image pipeline, formats, font loading, icon system, CDN and caching, LFS usage, and asset conventions. Flag every place where two units solve the same problem differently, and name the better baseline and why. Assets shared between units but copied rather than published from one source are a finding.

## Phase 5: Report

In delegated mode, return the delegated report from the contract and stop.

Otherwise report **in chat only**. Write no files in the repo. Keep it under about 2,500 words, in this order:

1. **Headline:** three sentences: overall health, the single most serious issue, and the single cheapest high-value fix.
2. **Inventory:** assets by unit and type with total sizes, the pipeline, and the largest files in the tree and in history.
3. **Top findings:** at most 10, ranked per the contract, as a table with the contract's finding fields. Keep each cell to one line. Put byte savings in "Why it matters" where you can estimate them.
4. **Per-unit summary:** at most 5 bullets per unit, covering what isn't already in Top findings.
5. **Clean:** one line per clean dimension: "Clean: checked X, Y, Z."
6. **Cross-repo drift:** a dimension × unit table where units differ, with the recommended baseline.
7. **Quick wins:** findings with Effort S, as a checklist.
8. **Could not verify:** skipped checks, why, and what it would take.
9. **Open questions for the team:** including every asset of unknown provenance that matters.

Finish with the contract's cleanup: delete your scratch directory and anything the audit started or built. Then offer to save the full report, including the complete unused-asset and oversized-asset lists, to a file outside the repo. Do neither unless the user asks.
