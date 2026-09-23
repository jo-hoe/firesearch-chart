# firecrawl-mcp

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: latest](https://img.shields.io/badge/AppVersion-latest-informational?style=flat-square)

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
| affinity | object | `{}` |  |
| api.image.pullPolicy | string | `"IfNotPresent"` |  |
| api.image.repository | string | `"ghcr.io/firecrawl/firecrawl"` |  |
| api.image.tag | string | `"latest"` |  |
| api.maxOldSpaceSizeMb | int | `6144` |  |
| api.port | int | `3002` |  |
| api.replicaCount | int | `1` |  |
| api.resources.limits.cpu | string | `"2000m"` |  |
| api.resources.limits.memory | string | `"6Gi"` |  |
| api.resources.requests.cpu | string | `"2000m"` |  |
| api.resources.requests.memory | string | `"4Gi"` |  |
| config.extra | object | `{}` |  |
| config.loggingLevel | string | `"INFO"` |  |
| config.modelEmbeddingName | string | `"text-embedding-3-small"` |  |
| config.modelName | string | `"gpt-4o-mini"` |  |
| config.numWorkersPerQueue | int | `8` |  |
| config.ollamaBaseUrl | string | `""` |  |
| config.openaiBaseUrl | string | `""` |  |
| config.useDbAuthentication | bool | `false` |  |
| fullnameOverride | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| mcp.endpoint | string | `"/v2/mcp"` |  |
| mcp.image.pullPolicy | string | `"IfNotPresent"` |  |
| mcp.image.repository | string | `"ghcr.io/firecrawl/firecrawl-mcp-server"` |  |
| mcp.image.tag | string | `"latest"` |  |
| mcp.ingress.annotations | object | `{}` |  |
| mcp.ingress.className | string | `""` |  |
| mcp.ingress.enabled | bool | `false` |  |
| mcp.ingress.hosts[0].host | string | `"firecrawl-mcp.local"` |  |
| mcp.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| mcp.ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| mcp.ingress.tls | list | `[]` |  |
| mcp.port | int | `8080` |  |
| mcp.replicaCount | int | `1` |  |
| mcp.resources.limits.cpu | string | `"500m"` |  |
| mcp.resources.limits.memory | string | `"512Mi"` |  |
| mcp.resources.requests.cpu | string | `"100m"` |  |
| mcp.resources.requests.memory | string | `"256Mi"` |  |
| mcp.service.port | int | `80` |  |
| mcp.service.type | string | `"ClusterIP"` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| nuqPostgres.auth.database | string | `"postgres"` |  |
| nuqPostgres.auth.password | string | `"postgres"` |  |
| nuqPostgres.auth.username | string | `"postgres"` |  |
| nuqPostgres.image.pullPolicy | string | `"IfNotPresent"` |  |
| nuqPostgres.image.repository | string | `"ghcr.io/firecrawl/nuq-postgres"` |  |
| nuqPostgres.image.tag | string | `"latest"` |  |
| nuqPostgres.persistence.accessModes[0] | string | `"ReadWriteOnce"` |  |
| nuqPostgres.persistence.enabled | bool | `false` |  |
| nuqPostgres.persistence.size | string | `"10Gi"` |  |
| nuqPostgres.persistence.storageClass | string | `""` |  |
| nuqPostgres.port | int | `5432` |  |
| nuqPostgres.replicaCount | int | `1` |  |
| nuqPostgres.resources.limits.cpu | string | `"500m"` |  |
| nuqPostgres.resources.limits.memory | string | `"1Gi"` |  |
| nuqPostgres.resources.requests.cpu | string | `"250m"` |  |
| nuqPostgres.resources.requests.memory | string | `"512Mi"` |  |
| nuqWorker.maxOldSpaceSizeMb | int | `3072` |  |
| nuqWorker.port | int | `3006` |  |
| nuqWorker.replicaCount | int | `5` |  |
| nuqWorker.resources.limits.cpu | string | `"1000m"` |  |
| nuqWorker.resources.limits.memory | string | `"4Gi"` |  |
| nuqWorker.resources.requests.cpu | string | `"1000m"` |  |
| nuqWorker.resources.requests.memory | string | `"3Gi"` |  |
| playwright.blockMedia | bool | `true` |  |
| playwright.image.pullPolicy | string | `"IfNotPresent"` |  |
| playwright.image.repository | string | `"ghcr.io/firecrawl/playwright-service"` |  |
| playwright.image.tag | string | `"latest"` |  |
| playwright.port | int | `3000` |  |
| playwright.replicaCount | int | `1` |  |
| playwright.resources.limits.cpu | string | `"2000m"` |  |
| playwright.resources.limits.memory | string | `"4Gi"` |  |
| playwright.resources.requests.cpu | string | `"1000m"` |  |
| playwright.resources.requests.memory | string | `"2Gi"` |  |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext.runAsNonRoot | bool | `false` |  |
| rabbitmq.image.pullPolicy | string | `"IfNotPresent"` |  |
| rabbitmq.image.repository | string | `"rabbitmq"` |  |
| rabbitmq.image.tag | string | `"3-management"` |  |
| rabbitmq.port | int | `5672` |  |
| rabbitmq.replicaCount | int | `1` |  |
| rabbitmq.resources.limits.cpu | string | `"500m"` |  |
| rabbitmq.resources.limits.memory | string | `"1Gi"` |  |
| rabbitmq.resources.requests.cpu | string | `"250m"` |  |
| rabbitmq.resources.requests.memory | string | `"512Mi"` |  |
| redis.image.pullPolicy | string | `"IfNotPresent"` |  |
| redis.image.repository | string | `"redis"` |  |
| redis.image.tag | string | `"alpine"` |  |
| redis.port | int | `6379` |  |
| redis.replicaCount | int | `1` |  |
| redis.resources.limits.cpu | string | `"500m"` |  |
| redis.resources.limits.memory | string | `"1Gi"` |  |
| redis.resources.requests.cpu | string | `"100m"` |  |
| redis.resources.requests.memory | string | `"256Mi"` |  |
| resources.enabled | bool | `true` |  |
| revisionHistoryLimit | int | `3` |  |
| secrets.existingSecret | string | `""` |  |
| secrets.openaiApiKey | string | `""` |  |
| secrets.postgresPassword | string | `"postgres"` |  |
| tolerations | list | `[]` |  |
| worker.maxOldSpaceSizeMb | int | `3072` |  |
| worker.port | int | `3005` |  |
| worker.replicaCount | int | `1` |  |
| worker.resources.limits.cpu | string | `"1000m"` |  |
| worker.resources.limits.memory | string | `"4Gi"` |  |
| worker.resources.requests.cpu | string | `"1000m"` |  |
| worker.resources.requests.memory | string | `"3Gi"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
