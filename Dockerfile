# syntax=docker/dockerfile:1

# ─────────────────────────────────────────────────────────────────────────────
# Stage 1 — Builder: clone Firesearch at a pinned ref, enable the standalone
# output, install dependencies, and build.
#
# This is a standalone deployment repo (it holds no application source), so the
# builder fetches the app itself. Pin the ref for reproducible builds:
#   docker build --build-arg FIRESEARCH_REF=<tag|branch|sha> -t firesearch:local .
# ─────────────────────────────────────────────────────────────────────────────
FROM node:25-alpine AS builder

# Firesearch git ref to build (tag, branch, or commit SHA).
ARG FIRESEARCH_REPO=https://github.com/firecrawl/firesearch.git
ARG FIRESEARCH_REF=main

# git for cloning; libc6-compat for native Node addons on Alpine (musl).
RUN apk add --no-cache git libc6-compat

# Firesearch uses pnpm. Pin a known-good pnpm version via corepack.
RUN corepack enable && corepack prepare pnpm@9.15.9 --activate

WORKDIR /app

# Shallow-clone the pinned ref into the build directory.
RUN git clone --depth 1 --branch "${FIRESEARCH_REF}" "${FIRESEARCH_REPO}" . \
    || git clone "${FIRESEARCH_REPO}" . && git checkout "${FIRESEARCH_REF}"

# Enable Next.js standalone output. Idempotent: only inject the option if the
# config does not already declare it.
RUN if ! grep -q "output:" next.config.ts; then \
      sed -i 's/const nextConfig: NextConfig = {/const nextConfig: NextConfig = {\n  output: "standalone",/' next.config.ts; \
    fi \
    && grep -q 'output: "standalone"' next.config.ts

# Install against the committed lockfile. pnpm 9 runs dependency build scripts
# by default (pnpm 10 would require approving them), so native deps like sharp
# and @tailwindcss/oxide compile without extra configuration.
RUN pnpm install --frozen-lockfile

# Build.
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm run build

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2 — Runner: minimal runtime image serving the standalone output.
# ─────────────────────────────────────────────────────────────────────────────
FROM node:25-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Run as a dedicated non-root user.
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs

# The standalone output bundles a minimal node_modules and a server.js entrypoint.
# Static assets and the public directory must be copied alongside it.
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
