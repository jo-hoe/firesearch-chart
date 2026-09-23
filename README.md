# Self-Hosted Firecrawl + MCP Server (Unofficial Helm Chart)

A Helm chart that deploys a **fully self-hosted [Firecrawl](https://github.com/firecrawl/firecrawl)
backend together with the Firecrawl MCP server**, so an MCP client such as
[Claude Code](https://docs.claude.com/en/docs/claude-code) can reach a
self-hosted Firecrawl over HTTP — **with no external API keys and no
`firecrawl.dev` account**.

> [!IMPORTANT]
> **Disclaimer — no affiliation.** This is an independent, community-maintained
> deployment project. It is **not** affiliated with, endorsed by, or sponsored
> by Firecrawl. "Firecrawl" and "MCP" are the property of their respective
> owners and are used here only to describe the upstream software this chart
> deploys (nominative use). No trademarks, logos, or icons of the upstream
> projects are included or redistributed.
>
> **Upstream software.** This repository contains only original deployment
> tooling (a Helm chart + CI). It builds no container image and redistributes no
> upstream source code — every component is pulled at deploy time from an
> official, published `ghcr.io/firecrawl/*` image. You are responsible for
> complying with the upstream projects' license terms. This deployment tooling
> is licensed under the MIT License (see `LICENSE`).

## What it deploys

| Component | Image | Role |
| --- | --- | --- |
| **mcp** | `ghcr.io/firecrawl/firecrawl-mcp-server` | The MCP endpoint your client connects to (HTTP/streamable). The only externally-exposed service. |
| api | `ghcr.io/firecrawl/firecrawl` | Firecrawl REST API the MCP server calls. |
| worker | `ghcr.io/firecrawl/firecrawl` | Queue worker. |
| nuq-worker | `ghcr.io/firecrawl/firecrawl` | NuQ scrape worker(s). |
| playwright | `ghcr.io/firecrawl/playwright-service` | Headless browser for rendering pages. |
| redis | `redis:alpine` | Cache / rate limiting. |
| rabbitmq | `rabbitmq:3-management` | Job queue. |
| nuq-postgres | `ghcr.io/firecrawl/nuq-postgres` | NuQ queue state (Postgres + pg_cron). |

The Firecrawl API runs with `USE_DB_AUTHENTICATION=false`, so it is
unauthenticated and the MCP server uses a dummy key. **Keep the whole stack
inside a trusted network.**

## Install

The chart is published as an **OCI artifact** to GitHub Container Registry —
no `helm repo add` needed.

### Production defaults

`values.yaml` ships upstream production sizing (5 NuQ workers, multi-GB pods).
This needs a real cluster with plenty of memory:

```bash
helm install firecrawl oci://ghcr.io/jo-hoe/charts/firecrawl-mcp \
  --version 0.1.0 \
  --namespace firecrawl --create-namespace \
  --set mcp.ingress.enabled=true \
  --set-string mcp.ingress.hosts[0].host=firecrawl-mcp.example.com
```

### Minimal footprint (laptop / k3d / homelab)

A ready-made `values-minimal.yaml` collapses the stack to a single small replica
per component (~4–6 GB total):

```bash
helm install firecrawl oci://ghcr.io/jo-hoe/charts/firecrawl-mcp \
  --version 0.1.0 \
  --namespace firecrawl --create-namespace \
  -f https://raw.githubusercontent.com/jo-hoe/firesearch-chart/main/charts/firecrawl-mcp/values-minimal.yaml \
  --set mcp.ingress.enabled=true \
  --set-string mcp.ingress.hosts[0].host=firecrawl-mcp.example.com
```

Or from a local checkout: `-f charts/firecrawl-mcp/values-minimal.yaml`.

## Connect Claude Code

Once the MCP Ingress is up, add it as an HTTP MCP server:

```bash
claude mcp add --transport http firecrawl https://firecrawl-mcp.example.com/v2/mcp
```

Without an Ingress, port-forward instead:

```bash
kubectl -n firecrawl port-forward svc/firecrawl-firecrawl-mcp-mcp 8080:80
claude mcp add --transport http firecrawl http://localhost:8080/v2/mcp
```

The tools (`firecrawl_scrape`, `firecrawl_search`, `firecrawl_crawl`,
`firecrawl_map`, …) then become available to the client.

## Scaling

Every component exposes `replicaCount` and `resources`; scale by overriding
them. Start from `values-minimal.yaml` and raise limits, or start from the
production defaults and trim. Examples:

```bash
# more scrape throughput
--set nuqWorker.replicaCount=5

# give the API more heap
--set api.maxOldSpaceSizeMb=6144
```

## Key values

| Value | Default | Description |
| --- | --- | --- |
| `<component>.replicaCount` | varies | Replicas per component (`api`, `worker`, `nuqWorker`, `playwright`, `mcp`, …). |
| `<component>.resources` | prod sizing | CPU/memory requests & limits (gated by `resources.enabled`). |
| `mcp.endpoint` | `/v2/mcp` | Public MCP path served by the MCP server. |
| `mcp.ingress.enabled` | `false` | Expose the MCP server via Ingress (the only external service). |
| `mcp.ingress.hosts` / `.tls` | — | Ingress host(s) and TLS config. |
| `config.useDbAuthentication` | `false` | Leave `false` for a keyless self-hosted API. |
| `config.openaiBaseUrl` | `""` | Optional: enable Firecrawl's AI features (summary / JSON extraction) by pointing at any OpenAI-compatible endpoint. Requires `secrets.openaiApiKey` too. |
| `config.modelName` | `gpt-4o-mini` | Chat model used for AI features. Override to match your endpoint's catalogue. |
| `nuqPostgres.persistence.enabled` | `false` | Enable a PVC for durable queue state (recommended in production). |
| `secrets.postgresPassword` | `postgres` | Password for the bundled Postgres. |
| `secrets.existingSecret` | `""` | Use a Secret you manage (keys `POSTGRES_PASSWORD`, `OPENAI_API_KEY`). |

## Local end-to-end testing with k3d

```bash
make k3d-test    # create cluster, deploy minimal stack + ingress, run helm test
make k3d-down    # tear down
```

`make k3d-test` deploys with `values-minimal.yaml`, waits for the API and MCP
server to be ready, and runs `helm test` (API readiness + a live MCP
`initialize` handshake).

## Production notes

- **Auth:** the API is unauthenticated (`config.useDbAuthentication=false`).
  Do not expose it; put an authenticating proxy in front of the MCP Ingress if
  it leaves your trusted network.
- **Persistence:** `nuqPostgres.persistence.enabled=false` by default — queue
  state is lost on pod restart. Enable a PVC for durability.
- **Sizing:** the defaults mirror upstream production values and are heavy; use
  `values-minimal.yaml` for small environments.

## AI features (summary / JSON extraction)

`firecrawl_scrape` with `formats: ["summary"]` (or JSON extraction) calls an LLM.
This is **off by default** and turns on when you set both `config.openaiBaseUrl`
and `secrets.openaiApiKey`:

```bash
--set-string config.openaiBaseUrl=https://your-openai-endpoint/v1 \
--set-string config.modelName=gpt-4o-mini \
--set-string secrets.openaiApiKey=sk-...
```

Firecrawl uses the OpenAI **Responses API** (`POST <baseUrl>/responses`), not
`/chat/completions`. Your endpoint and the chosen `config.modelName` must both
support that route — some OpenAI-compatible gateways only expose
`/chat/completions`, or allow `/responses` for a subset of models. If AI calls
fail with a `Subpath 'responses' is not allowed` / 400 error, pick a model your
endpoint permits on `/responses`. Core scraping/crawling needs none of this.

## CI / Release

- **`ci.yml`** — on every push/PR: lints the chart (`--strict`), renders it
  with both the production defaults and the minimal values, and verifies the
  chart README is up to date (helm-docs).
- **`chart-release.yml`** — on `v*.*.*` tags: re-checks the helm-docs README,
  then packages the chart and pushes it as an OCI artifact to
  `oci://ghcr.io/jo-hoe/charts/firecrawl-mcp`.
- **`dependabot-auto-merge.yml`** — auto-merges green Dependabot PRs.

### Chart docs

The chart's own `README.md` (values reference) is generated from `values.yaml`
with [helm-docs](https://github.com/norwoodj/helm-docs):

```bash
make generate-helm-docs   # runs jnorwood/helm-docs in Docker; no local install
```

CI fails if the committed chart README drifts from `values.yaml` — regenerate
and commit after changing values.

### Cutting a release

```bash
# bump version in charts/firecrawl-mcp/Chart.yaml first, then:
git tag v0.1.0
git push origin v0.1.0
```

## Repository layout

| Path | Purpose |
| --- | --- |
| `charts/firecrawl-mcp/` | The Helm chart (all components, MCP ingress, tests). |
| `charts/firecrawl-mcp/values-minimal.yaml` | Minimal-footprint override. |
| `k3d/cluster.yaml` | Local k3d cluster config for end-to-end testing. |
| `Makefile` | Lint / template / package / k3d workflows. |
| `.github/workflows/` | Chart lint + OCI release + Dependabot auto-merge. |
