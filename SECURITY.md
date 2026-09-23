# Security Policy

## Supported Versions

Security fixes are applied to the latest released version of the chart and image.

## Reporting a Vulnerability

Please report security issues privately via GitHub's
[private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
on this repository, or open a
[security advisory](../../security/advisories/new).

Do **not** open a public issue for security reports. We aim to acknowledge
reports within 5 business days.

## Handling of Secrets

- API keys (`OPENAI_API_KEY`, `OPENAI_BASE_URL`, `FIRECRAWL_API_KEY`) are stored
  in a Kubernetes `Secret` and injected into the container via `secretKeyRef`.
  They are **never** baked into the image.
- The chart supports referencing an externally-managed Secret via
  `secrets.existingSecret`, so you can integrate with tools like
  External Secrets Operator, Sealed Secrets, or a cloud secret manager.
- `.gitignore` and `.dockerignore` exclude `.env*` files and `*.local.yaml`
  values so secrets are not committed to git or copied into the build context.
- Never commit real API keys to values files. Use `--set-string` at install
  time or an `existingSecret`.

## Container Hardening

The runtime image and Deployment apply the following by default:

- Runs as a **non-root** user (UID/GID 1001).
- `readOnlyRootFilesystem: true` with writable `emptyDir` volumes only where
  Next.js requires them (`.next/cache`, `/tmp`).
- `allowPrivilegeEscalation: false` and all Linux capabilities dropped.
- Multi-stage build ships only the Next.js standalone output — no build
  toolchain or dev dependencies in the final image.

## Network Exposure

- The Service defaults to `ClusterIP` (no external exposure).
- Ingress is **disabled by default**; enable and configure TLS explicitly.
