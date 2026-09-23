# Firesearch — Self-Hosted Deployment (Unofficial)

Container image and Helm chart for self-hosting
[Firesearch](https://github.com/firecrawl/firesearch), a deep-research app built
on Next.js.

> [!IMPORTANT]
> **Disclaimer — no affiliation.** This is an independent, community-maintained
> deployment project. It is **not** affiliated with, endorsed by, or sponsored
> by Firecrawl or the Firesearch maintainers. "Firesearch" and "Firecrawl" are
> the property of their respective owners and are used here only to describe the
> upstream software this project deploys (nominative use). No trademarks, logos,
> or icons of the upstream project are included or redistributed.
>
> **Upstream license.** This repository contains only original deployment
> tooling (Dockerfile, Helm chart, CI). It does **not** redistribute Firesearch
> source code — the image is built by cloning the upstream repository at build
> time. The Firesearch README states an MIT license, but at the time of writing
> the upstream repository does **not contain a `LICENSE` file**. Before building,
> distributing, or hosting the resulting image, **verify the upstream license
> terms yourself** (e.g. open an issue upstream asking them to add a `LICENSE`
> file). You are responsible for your own compliance.
>
> This deployment tooling is licensed under the MIT License (see `LICENSE`).

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

The chart is published as an **OCI artifact** to GitHub Container Registry, and
the container image is published alongside it on each version tag. Install
directly from the registry — no `helm repo add` needed:

```bash
helm install firesearch oci://ghcr.io/jo-hoe/charts/firesearch \
  --version 0.2.0 \
  --namespace firesearch --create-namespace \
  --set-string secrets.openaiApiKey=sk-... \
  --set-string secrets.firecrawlApiKey=fc-... \
  --set-string secrets.openaiBaseUrl=https://your-openai-compatible-endpoint/
```

Or from a local checkout of this repo:

```bash
helm install firesearch charts/firesearch \
  --namespace firesearch --create-namespace \
  --set-string secrets.openaiApiKey=sk-... \
  --set-string secrets.firecrawlApiKey=fc-...
```

API keys are rendered into a Kubernetes Secret; the Deployment consumes them as
environment variables via `secretKeyRef`.

To use a Secret you manage yourself instead of having the chart create one:

```bash
helm install firesearch oci://ghcr.io/jo-hoe/charts/firesearch --version 0.2.0 \
  --set secrets.existingSecret=my-firesearch-secret
```

The existing Secret must contain keys `OPENAI_API_KEY`, `OPENAI_BASE_URL`,
and `FIRECRAWL_API_KEY`.

### Key values

| Value | Default | Description |
| --- | --- | --- |
| `replicaCount` | `1` | Number of replicas (stateless; scales horizontally). |
| `image.repository` | `ghcr.io/jo-hoe/firesearch-chart` | Image repo. |
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

- **`ci.yml`** — on every push/PR: lints the Helm chart and builds the container
  image (the real integration test — the Dockerfile clones Firesearch at build
  time). On `v*.*.*` tags it also publishes the image to `ghcr.io` with semver
  tags.
- **`chart-release.yml`** — on `v*.*.*` tags: packages the chart and pushes it as
  an OCI artifact to `oci://ghcr.io/jo-hoe/charts/firesearch`. No gh-pages branch.
- **`dependabot-auto-merge.yml`** — auto-merges green Dependabot PRs.

### Cutting a release

Both the image and the chart publish off the same version tag:

```bash
# bump chart version + appVersion in charts/firesearch/Chart.yaml first, then:
git tag v0.2.0
git push origin v0.2.0
```
