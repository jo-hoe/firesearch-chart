# Firesearch — Self-Hosted Deployment

Container image and Helm chart for self-hosting [Firesearch](https://github.com/firecrawl/firesearch),
a Firecrawl-powered deep-research app built on Next.js 15.

## Contents

| Path | Purpose |
| --- | --- |
| `Dockerfile` | Multi-stage build (node:20-alpine) producing a Next.js **standalone** runtime image. |
| `next.config.standalone.ts` | Reference `next.config.ts` with `output: 'standalone'` added. |
| `charts/firesearch/` | Helm chart (Deployment, Service, Ingress, Secret, ServiceAccount). |
| `k3d/` | Local k3d cluster config + example values for end-to-end testing. |
| `Makefile` | Build / lint / package / k3d workflows. |
| `.github/workflows/` | CI (lint + build + image publish), chart release, Dependabot auto-merge. |

## Prerequisites

The Firesearch source must have `output: 'standalone'` in its `next.config.ts`.
Copy `next.config.standalone.ts` over the upstream config, or add the one line
manually. The Dockerfile expects to build from the Firesearch repo root.

## Build the image

```bash
make build                 # docker build -t firesearch:local .
```

## Deploy with Helm

API keys are supplied as values and rendered into a Kubernetes Secret; the
Deployment consumes them as environment variables via `secretKeyRef`.

```bash
helm install firesearch charts/firesearch \
  --namespace firesearch --create-namespace \
  --set-string secrets.openaiApiKey=sk-... \
  --set-string secrets.firecrawlApiKey=fc-... \
  --set-string secrets.openaiBaseUrl=https://your-openai-compatible-endpoint/
```

To use a Secret you manage yourself instead of having the chart create one:

```bash
helm install firesearch charts/firesearch \
  --set secrets.existingSecret=my-firesearch-secret
```

The existing Secret must contain keys `OPENAI_API_KEY`, `OPENAI_BASE_URL`,
and `FIRECRAWL_API_KEY`.

### Key values

| Value | Default | Description |
| --- | --- | --- |
| `replicaCount` | `1` | Number of replicas (stateless; scales horizontally). |
| `image.repository` | `ghcr.io/firecrawl/firesearch` | Image repo. |
| `image.tag` | `""` (chart appVersion) | Image tag. |
| `resources` | 500m/512Mi limits | CPU/memory limits & requests. |
| `ingress.enabled` | `false` | Toggle Ingress (off by default). |
| `service.type` | `ClusterIP` | Service type. |
| `secrets.existingSecret` | `""` | Reference an out-of-band Secret. |

## Local end-to-end testing with k3d

```bash
cp k3d/values.example.yaml k3d/values.local.yaml   # then fill in API keys
make k3d-test                                        # create cluster, build, deploy, smoke-test
```

`k3d/values.local.yaml` is git-ignored and is the only place local secrets live.
Tear down with `make k3d-down`.

## CI / Release

- **`ci.yml`** — on every push/PR: lints & builds the app and the chart; on
  `v*.*.*` tags: builds and publishes the image to `ghcr.io` with semver tags.
- **`chart-release.yml`** — on changes to `charts/firesearch/Chart.yaml`:
  packages and publishes the chart to the `gh-pages` Helm repository via
  `helm/chart-releaser-action`.
- **`dependabot-auto-merge.yml`** — auto-merges green Dependabot PRs.
