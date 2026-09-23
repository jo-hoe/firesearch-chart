# firecrawl-mcp

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: latest](https://img.shields.io/badge/AppVersion-latest-informational?style=flat-square)

An unofficial Helm chart for a fully self-hosted Firecrawl backend and Firecrawl MCP server. Lets an MCP client (e.g. Claude Code) reach a self-hosted Firecrawl over HTTP with no external API keys. Not affiliated with or endorsed by Firecrawl.

**Homepage:** <https://github.com/jo-hoe/firesearch-chart>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| jo-hoe |  | <https://github.com/jo-hoe> |

## Source Code

* <https://github.com/jo-hoe/firesearch-chart>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for all pods. |
| api.image.pullPolicy | string | `"IfNotPresent"` | Firecrawl API image pull policy. |
| api.image.repository | string | `"ghcr.io/firecrawl/firecrawl"` | Firecrawl API image repository (also used by the workers). |
| api.image.tag | string | `"latest"` | Firecrawl API image tag. |
| api.maxOldSpaceSizeMb | int | `6144` | Node heap ceiling for the API in MB (passed to Node's max-old-space-size; keep below the memory limit). |
| api.port | int | `3002` | Container port the API listens on. |
| api.replicaCount | int | `1` | Number of Firecrawl API replicas. |
| api.resources | object | `{"limits":{"cpu":"2000m","memory":"6Gi"},"requests":{"cpu":"2000m","memory":"4Gi"}}` | CPU/memory requests and limits for the API pod. |
| config.extra | object | `{}` | Arbitrary extra key/value pairs merged into the ConfigMap. |
| config.loggingLevel | string | `"INFO"` | Firecrawl log level (e.g. DEBUG, INFO, WARN, ERROR). |
| config.modelEmbeddingName | string | `"text-embedding-3-small"` | Embedding model (only needed by features that embed text). |
| config.modelName | string | `"gpt-4o-mini"` | Chat model used for summary/extraction. Override to match your endpoint. |
| config.numWorkersPerQueue | int | `8` | Number of concurrent workers per queue. |
| config.ollamaBaseUrl | string | `""` | Ollama base URL, as an alternative to an OpenAI-compatible endpoint. |
| config.openaiBaseUrl | string | `""` | OpenAI-compatible base URL enabling AI features (summary / JSON extraction). Only active when set AND secrets.openaiApiKey is provided. Firecrawl uses the OpenAI *Responses API* (/responses), so the endpoint and chosen model must support it. |
| config.useDbAuthentication | bool | `false` | When false the self-hosted API is UNAUTHENTICATED. Do NOT expose the API outside a trusted network without adding real authentication first. |
| fullnameOverride | string | `""` | Override the full name of resources (replaces the release-name prefix). |
| imagePullSecrets | list | `[]` | Image pull secrets applied to every pod. |
| mcp.endpoint | string | `"/v2/mcp"` | Public MCP path the FastMCP server and nginx serve. MCP clients connect to `<ingress-host><endpoint>`. Keep in sync with any Ingress paths. |
| mcp.image.pullPolicy | string | `"IfNotPresent"` | MCP server image pull policy. |
| mcp.image.repository | string | `"ghcr.io/firecrawl/firecrawl-mcp-server"` | MCP server image repository. |
| mcp.image.tag | string | `"latest"` | MCP server image tag. |
| mcp.ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"firecrawl-mcp.local","paths":[{"path":"/","pathType":"Prefix"}]}],"tls":[]}` | Ingress for the MCP server — the ONLY externally-exposed component. |
| mcp.port | int | `8080` | Container port the MCP image serves HTTP (NGINX + FastMCP) on. |
| mcp.replicaCount | int | `1` | Number of MCP server replicas. |
| mcp.resources | object | `{"limits":{"cpu":"500m","memory":"512Mi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | CPU/memory requests and limits for the MCP server pod. |
| mcp.service.port | int | `80` | MCP Service port. |
| mcp.service.type | string | `"ClusterIP"` | MCP Service type. |
| nameOverride | string | `""` | Override the chart name portion of resource names. |
| nodeSelector | object | `{}` | Node selector for all pods. |
| nuqPostgres.auth.database | string | `"postgres"` | Postgres database name. |
| nuqPostgres.auth.password | string | `"postgres"` | Postgres password. Overridden by secrets.postgresPassword (or an existingSecret); this non-secret default is for local use only — set a real password in production. |
| nuqPostgres.auth.username | string | `"postgres"` | Postgres username used in the composed NUQ_DATABASE_URL. |
| nuqPostgres.image.pullPolicy | string | `"IfNotPresent"` | NuQ Postgres image pull policy. |
| nuqPostgres.image.repository | string | `"ghcr.io/firecrawl/nuq-postgres"` | NuQ Postgres image repository (Postgres + pg_cron). |
| nuqPostgres.image.tag | string | `"latest"` | NuQ Postgres image tag. |
| nuqPostgres.persistence | object | `{"accessModes":["ReadWriteOnce"],"enabled":false,"size":"10Gi","storageClass":""}` | Persistence for the NuQ Postgres data. OFF BY DEFAULT: queue state (and any crawl results held in Postgres) is LOST when the pod is replaced. Enable for anything you care about surviving restarts. |
| nuqPostgres.port | int | `5432` | Container port Postgres listens on. |
| nuqPostgres.replicaCount | int | `1` | Number of NuQ Postgres replicas (should remain 1). |
| nuqPostgres.resources | object | `{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"250m","memory":"512Mi"}}` | CPU/memory requests and limits for the Postgres pod. |
| nuqWorker.maxOldSpaceSizeMb | int | `3072` | Node heap ceiling for each NuQ worker (MB). |
| nuqWorker.port | int | `3006` | Container port the NuQ worker exposes for health checks. |
| nuqWorker.replicaCount | int | `5` | Number of NuQ worker replicas (the primary scrape/crawl workers). Raise for more scrape throughput. |
| nuqWorker.resources | object | `{"limits":{"cpu":"1000m","memory":"4Gi"},"requests":{"cpu":"1000m","memory":"3Gi"}}` | CPU/memory requests and limits per NuQ worker pod. |
| playwright.blockMedia | bool | `true` | Block images/media to save bandwidth and memory during scraping. |
| playwright.image.pullPolicy | string | `"IfNotPresent"` | Playwright service image pull policy. |
| playwright.image.repository | string | `"ghcr.io/firecrawl/playwright-service"` | Playwright service image repository. |
| playwright.image.tag | string | `"latest"` | Playwright service image tag. |
| playwright.port | int | `3000` | Container port the Playwright service listens on. |
| playwright.replicaCount | int | `1` | Number of Playwright microservice replicas. |
| playwright.resources | object | `{"limits":{"cpu":"2000m","memory":"4Gi"},"requests":{"cpu":"1000m","memory":"2Gi"}}` | CPU/memory requests and limits for the Playwright pod. |
| podAnnotations | object | `{}` | Annotations added to every pod. |
| podLabels | object | `{}` | Labels added to every pod. |
| podSecurityContext | object | `{"runAsNonRoot":false}` | Pod-level security context. Firecrawl/Playwright images may write to the filesystem, so readOnlyRootFilesystem is not enforced globally; see each Deployment for the container-level context. |
| rabbitmq.image.pullPolicy | string | `"IfNotPresent"` | RabbitMQ image pull policy. |
| rabbitmq.image.repository | string | `"rabbitmq"` | RabbitMQ image repository. |
| rabbitmq.image.tag | string | `"3-management"` | RabbitMQ image tag. |
| rabbitmq.port | int | `5672` | Container port RabbitMQ listens on (AMQP). |
| rabbitmq.replicaCount | int | `1` | Number of RabbitMQ replicas (should remain 1; not clustered). |
| rabbitmq.resources | object | `{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"250m","memory":"512Mi"}}` | CPU/memory requests and limits for the RabbitMQ pod. |
| redis.image.pullPolicy | string | `"IfNotPresent"` | Redis image pull policy. |
| redis.image.repository | string | `"redis"` | Redis image repository. |
| redis.image.tag | string | `"alpine"` | Redis image tag. |
| redis.port | int | `6379` | Container port Redis listens on. |
| redis.replicaCount | int | `1` | Number of Redis replicas (should remain 1; not clustered). |
| redis.resources | object | `{"limits":{"cpu":"500m","memory":"1Gi"},"requests":{"cpu":"100m","memory":"256Mi"}}` | CPU/memory requests and limits for the Redis pod. |
| resources.enabled | bool | `true` | Master switch for applying the per-component `resources` blocks. Set false to let pods run without requests/limits (handy for quick local experiments). |
| revisionHistoryLimit | int | `3` | Number of old ReplicaSets to retain for rollback (applies to all Deployments). |
| secrets.existingSecret | string | `""` | If set, the chart will NOT create a Secret and reads credentials from this pre-existing Secret. It must contain keys: POSTGRES_PASSWORD, OPENAI_API_KEY. |
| secrets.openaiApiKey | string | `""` | OpenAI(-compatible) API key. Only needed to enable AI features. |
| secrets.postgresPassword | string | `"postgres"` | Password for the bundled NuQ PostgreSQL. Must match nuqPostgres.auth.password. |
| tolerations | list | `[]` | Tolerations for all pods. |
| worker.maxOldSpaceSizeMb | int | `3072` | Node heap ceiling for the queue worker (MB). |
| worker.port | int | `3005` | Container port the queue worker exposes for health checks. |
| worker.replicaCount | int | `1` | Number of queue-worker replicas. |
| worker.resources | object | `{"limits":{"cpu":"1000m","memory":"4Gi"},"requests":{"cpu":"1000m","memory":"3Gi"}}` | CPU/memory requests and limits for the queue-worker pod. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
