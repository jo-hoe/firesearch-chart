# Security Policy

## Supported Versions

Security fixes are applied to the latest released version of the chart.

## Reporting a Vulnerability

Please report security issues privately via GitHub's
[private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
on this repository, or open a
[security advisory](../../security/advisories/new).

Do **not** open a public issue for security reports. We aim to acknowledge
reports within 5 business days.

## Scope

This repository ships **only a Helm chart**. It builds no container image; every
component is deployed from an official, upstream `ghcr.io/firecrawl/*` image.
Vulnerabilities in the Firecrawl or MCP server images themselves should be
reported to the [Firecrawl project](https://github.com/firecrawl/firecrawl); this
policy covers the chart templates and their default configuration.

## Handling of Secrets

- The only secret the chart manages is the internal Postgres password (and an
  optional `OPENAI_API_KEY` for Firecrawl's AI-powered extraction features). It
  is stored in a Kubernetes `Secret` and injected via `secretKeyRef` /
  `envFrom` — never rendered into a ConfigMap or image.
- The chart supports referencing an externally-managed Secret via
  `secrets.existingSecret`, so you can integrate with tools like
  External Secrets Operator, Sealed Secrets, or a cloud secret manager.
- `.gitignore` excludes `*.local.yaml` values files so machine-specific config
  and secrets are not committed to git.
- Never commit real secrets to values files. Use `--set-string` at install time
  or an `existingSecret`.

## Authentication & Network Exposure

- The self-hosted Firecrawl API runs with `USE_DB_AUTHENTICATION=false` by
  default, which means **the API is unauthenticated**. The MCP server likewise
  accepts any client. Keep both inside a trusted network.
- All internal Services default to `ClusterIP` (no external exposure).
- Only the MCP server can be exposed externally, and only when
  `mcp.ingress.enabled=true`. Ingress is **disabled by default**; enable and
  configure TLS explicitly, and put an authenticating proxy in front of it if it
  leaves your trusted network.

## Container Hardening

- Pod- and container-level `securityContext` are exposed as values and applied
  to the chart's own workloads.
- The helm test pod drops all Linux capabilities, disables privilege
  escalation, and runs as a non-root UID.
- Some upstream Firecrawl images require a writable filesystem; where
  `readOnlyRootFilesystem` cannot be enabled, the relevant paths are documented
  in the component templates.
