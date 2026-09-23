---
name: release
description: Release a new version of the firecrawl-mcp Helm chart. Bumps Chart.yaml, regenerates the helm-docs README, commits, pushes, tags, babysits CI, and verifies the published OCI artifact. Run in foreground (run_in_background: false) so step progress is visible in real time.
allowedTools:
  - Read
  - Edit
  - Bash(git *)
  - Bash(gh *)
  - Bash(helm *)
  - Bash(docker *)
  - Bash(grep *)
---

## Release process for firecrawl-mcp Helm chart

This is a **chart-only** repository — there is no application image to build. A
release bumps `version` in `Chart.yaml`, regenerates the helm-docs README,
commits everything, pushes to `main`, and then pushes a semver tag which
triggers `chart-release.yml` to package and publish the chart as an OCI
artifact to `ghcr.io/jo-hoe/charts/firecrawl-mcp`.

Follow these steps in order. Do not skip steps. After each step report
completion with a one-line status so the user can track progress.

---

### Step 1 — Determine the new version

Report: `[Step 1/5] Determining new version...`

Check the current chart version and recent changes:
```bash
grep -E '^version:' charts/firecrawl-mcp/Chart.yaml
git tag --sort=-v:refname | head -3
git log $(git tag --sort=-v:refname | head -1)..HEAD --oneline
git diff $(git tag --sort=-v:refname | head -1)..HEAD -- charts/firecrawl-mcp/
```

If there are **no changes** to `charts/firecrawl-mcp/` since the last tag, stop
here and report:
`[Step 1/5] No release needed — no chart changes since last tag.`

Otherwise, determine the new semver by following conventional commits in the
log:
- `feat:` → minor bump  
- `fix:` / `chore:` / `docs:` → patch bump  
- `BREAKING CHANGE` anywhere → major bump  

If Chart.yaml already has an unreleased version bump (i.e. `version` is ahead
of the latest tag), use that as the new version.

Report: `[Step 1/5] ✓ New chart version: <new-version> (was <old-version>)`

---

### Step 2 — Bump Chart.yaml and regenerate docs

Report: `[Step 2/5] Bumping Chart.yaml and regenerating helm-docs README...`

Update `version` in `charts/firecrawl-mcp/Chart.yaml`:
```yaml
version: <new-version>
```

Then regenerate the helm-docs README so it reflects the current values.yaml:
```bash
docker run --rm \
  --volume "$PWD/charts/firecrawl-mcp:/helm-docs" \
  jnorwood/helm-docs:latest
```

Verify the README now shows the correct version badge:
```bash
grep "Version:" charts/firecrawl-mcp/README.md | head -1
```

Report: `[Step 2/5] ✓ Chart.yaml bumped to <new-version>, README regenerated`

---

### Step 3 — Commit and push

Report: `[Step 3/5] Committing and pushing...`

Stage all chart changes (including any outstanding working-tree modifications):
```bash
git status --short
git add charts/firecrawl-mcp/
git status --short
```

Check if there are any other modified or untracked files outside `charts/` (e.g.
`.claude/`, CI, Makefile). If so, stage and commit those first with an
appropriate message, then commit the chart bump separately.

Commit the chart release:
```bash
git commit -m "chore: release chart v<new-version>"
git push origin main
```

If push fails due to remote changes, rebase first:
```bash
git fetch origin && git rebase origin/main
```
Then re-push.

Report: `[Step 3/5] ✓ Pushed main`

---

### Step 4 — Push the release tag

Report: `[Step 4/5] Pushing release tag v<new-version>...`

The `chart-release.yml` workflow triggers on `v*.*.*` tags:
```bash
git tag v<new-version>
git push origin v<new-version>
```

Report: `[Step 4/5] ✓ Tag v<new-version> pushed`

---

### Step 5 — Babysit CI and verify

Report: `[Step 5/5] Waiting for CI (timeout: 10 minutes)...`

Poll every 30 seconds, up to 20 times:
```bash
gh run list --repo jo-hoe/firesearch-chart --limit 5
```

Track both workflows triggered by the tag push:
- `Release Chart` — triggered by the semver tag, packages and pushes to GHCR

Report each poll as:
`[Step 5/5] Poll <n>/20 — release: <status>`

Stop as soon as the workflow shows `completed`. If it shows `failure`, fetch
the logs immediately:
```bash
gh run view <id> --log-failed
```
Then report the failure and stop.

If 20 polls pass without completion: `[Step 5/5] ✗ Timeout after 10 minutes`
and stop.

Once CI completes, verify the published chart:
```bash
helm show chart oci://ghcr.io/jo-hoe/charts/firecrawl-mcp --version <new-version>
```

If verification fails, report the error.

Report: `[Step 5/5] ✓ Release complete`

Confirm:
- Chart: `oci://ghcr.io/jo-hoe/charts/firecrawl-mcp --version <new-version>`
- Install: `helm install firecrawl oci://ghcr.io/jo-hoe/charts/firecrawl-mcp --version <new-version>`
