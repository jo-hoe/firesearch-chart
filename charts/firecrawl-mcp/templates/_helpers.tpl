{{/*
Expand the name of the chart.
*/}}
{{- define "firecrawl-mcp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
Truncated at 63 chars because some Kubernetes name fields are limited to this.
*/}}
{{- define "firecrawl-mcp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "firecrawl-mcp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "firecrawl-mcp.labels" -}}
helm.sh/chart: {{ include "firecrawl-mcp.chart" . }}
app.kubernetes.io/part-of: {{ include "firecrawl-mcp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Component labels. Pass the component name as the second arg, e.g.
  {{ include "firecrawl-mcp.componentLabels" (list . "api") }}
*/}}
{{- define "firecrawl-mcp.componentLabels" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
{{ include "firecrawl-mcp.labels" $root }}
app.kubernetes.io/name: {{ printf "%s-%s" (include "firecrawl-mcp.name" $root) $component }}
app.kubernetes.io/component: {{ $component }}
{{- end }}

{{/*
Selector labels for a component. Pass the component name as the second arg.
These are the immutable subset used in Deployment selectors and Service
selectors — they must NOT include version/chart labels that change on upgrade.
*/}}
{{- define "firecrawl-mcp.selectorLabels" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
app.kubernetes.io/name: {{ printf "%s-%s" (include "firecrawl-mcp.name" $root) $component }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
app.kubernetes.io/component: {{ $component }}
{{- end }}

{{/*
Fully-qualified per-component resource name, e.g. "<release>-firecrawl-mcp-api".
Pass the component suffix as the second arg.
*/}}
{{- define "firecrawl-mcp.componentName" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
{{- printf "%s-%s" (include "firecrawl-mcp.fullname" $root) $component | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
The name of the ServiceAccount used by every pod. Either a user-provided
existing account or one created by this chart.
*/}}
{{- define "firecrawl-mcp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "firecrawl-mcp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Pod-level securityContext, applied to every Deployment's pod spec. Merges the
chart-wide default (.Values.podSecurityContext) with an optional per-component
override passed as the second list arg. The per-component map wins on conflict.
  {{ include "firecrawl-mcp.podSecurityContext" (list . .Values.nuqPostgres.podSecurityContext) }}
*/}}
{{- define "firecrawl-mcp.podSecurityContext" -}}
{{- $root := index . 0 -}}
{{- $override := dict -}}
{{- if gt (len .) 1 -}}{{- $override = index . 1 | default dict -}}{{- end -}}
{{- $ctx := mergeOverwrite (deepCopy $root.Values.podSecurityContext) $override -}}
{{- toYaml $ctx }}
{{- end }}

{{/*
Container-level securityContext, applied to every workload container. Merges the
chart-wide hardened defaults (.Values.containerSecurityContext) with an optional
per-component override passed as the second list arg, e.g.
  {{ include "firecrawl-mcp.containerSecurityContext" (list . .Values.playwright.containerSecurityContext) }}
The per-component map wins on conflicting keys.
*/}}
{{- define "firecrawl-mcp.containerSecurityContext" -}}
{{- $root := index . 0 -}}
{{- $override := index . 1 | default dict -}}
{{- $ctx := mergeOverwrite (deepCopy $root.Values.containerSecurityContext) $override -}}
{{- toYaml $ctx }}
{{- end }}

{{/*
The name of the Secret holding credentials — either a user-provided existing
Secret or one created by this chart.
*/}}
{{- define "firecrawl-mcp.secretName" -}}
{{- if .Values.secrets.existingSecret }}
{{- .Values.secrets.existingSecret }}
{{- else }}
{{- include "firecrawl-mcp.fullname" . }}
{{- end }}
{{- end }}

{{/*
The name of the shared Firecrawl ConfigMap.
*/}}
{{- define "firecrawl-mcp.configName" -}}
{{- printf "%s-config" (include "firecrawl-mcp.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* ── In-cluster service DNS names (single source of truth) ── */}}

{{- define "firecrawl-mcp.apiHost" -}}
{{- include "firecrawl-mcp.componentName" (list . "api") }}
{{- end }}

{{- define "firecrawl-mcp.redisHost" -}}
{{- include "firecrawl-mcp.componentName" (list . "redis") }}
{{- end }}

{{- define "firecrawl-mcp.playwrightHost" -}}
{{- include "firecrawl-mcp.componentName" (list . "playwright") }}
{{- end }}

{{- define "firecrawl-mcp.postgresHost" -}}
{{- include "firecrawl-mcp.componentName" (list . "nuq-postgres") }}
{{- end }}

{{- define "firecrawl-mcp.rabbitmqHost" -}}
{{- include "firecrawl-mcp.componentName" (list . "rabbitmq") }}
{{- end }}

{{/* ── Composed connection URLs consumed by the Firecrawl ConfigMap ── */}}

{{- define "firecrawl-mcp.redisUrl" -}}
{{- printf "redis://%s:%v" (include "firecrawl-mcp.redisHost" .) .Values.redis.port }}
{{- end }}

{{- define "firecrawl-mcp.playwrightUrl" -}}
{{- printf "http://%s:%v/scrape" (include "firecrawl-mcp.playwrightHost" .) .Values.playwright.port }}
{{- end }}

{{- define "firecrawl-mcp.rabbitmqUrl" -}}
{{- printf "amqp://%s:%v" (include "firecrawl-mcp.rabbitmqHost" .) .Values.rabbitmq.port }}
{{- end }}

{{- define "firecrawl-mcp.postgresUrl" -}}
{{- printf "postgresql://%s:%s@%s:%v/%s" .Values.nuqPostgres.auth.username .Values.nuqPostgres.auth.password (include "firecrawl-mcp.postgresHost" .) .Values.nuqPostgres.port .Values.nuqPostgres.auth.database }}
{{- end }}

{{- define "firecrawl-mcp.firecrawlApiUrl" -}}
{{- printf "http://%s:%v" (include "firecrawl-mcp.apiHost" .) .Values.api.port }}
{{- end }}
