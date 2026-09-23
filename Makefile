# firecrawl-mcp — self-hosted Firecrawl + MCP server (Helm chart)
#
# Common targets for linting/packaging the Helm chart and spinning up a local
# k3d cluster for end-to-end testing. There is no custom image to build: every
# component uses an official, anonymously-pullable ghcr.io/firecrawl/* image.

# ── Configuration (override on the command line, e.g. `make package`) ─────────
# Absolute path to this Makefile's directory (trailing slash), used for Docker
# volume mounts.
ROOT_DIR      := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
CHART_DIR     ?= charts/firecrawl-mcp
RELEASE_NAME  ?= firecrawl
NAMESPACE     ?= firecrawl
# Minimal-footprint values so the whole stack fits on a laptop / k3d / homelab.
MINIMAL_VALUES ?= $(CHART_DIR)/values-minimal.yaml
# Ingress host used for the local k3d smoke test.
MCP_HOST      ?= firecrawl-mcp.localhost
# helm-docs image used to (re)generate the chart README from values.yaml.
HELM_DOCS_IMAGE ?= jnorwood/helm-docs:latest

# k3d specifics
K3D_CLUSTER   ?= firesearch
K3D_CONFIG    ?= k3d/cluster.yaml

.DEFAULT_GOAL := help

# ── Meta ──────────────────────────────────────────────────────────────────────
.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ── Helm ──────────────────────────────────────────────────────────────────────
.PHONY: lint
lint: ## Lint the Helm chart
	helm lint $(CHART_DIR) --strict

.PHONY: template
template: ## Render the chart to stdout (production defaults)
	helm template $(RELEASE_NAME) $(CHART_DIR)

.PHONY: template-minimal
template-minimal: ## Render the chart with the minimal-footprint values
	helm template $(RELEASE_NAME) $(CHART_DIR) -f $(MINIMAL_VALUES)

.PHONY: package
package: ## Package the chart into a .tgz
	helm package $(CHART_DIR)

.PHONY: generate-helm-docs
generate-helm-docs: ## Generate the chart README from values.yaml via helm-docs
	@docker run --rm --volume "$(ROOT_DIR)$(CHART_DIR):/helm-docs" $(HELM_DOCS_IMAGE)

# ── k3d end-to-end ────────────────────────────────────────────────────────────
.PHONY: k3d-up
k3d-up: ## Create the local k3d cluster (with ingress)
	k3d cluster create --config $(K3D_CONFIG)

.PHONY: k3d-down
k3d-down: ## Delete the local k3d cluster
	k3d cluster delete $(K3D_CLUSTER)

.PHONY: k3d-deploy
k3d-deploy: ## Deploy the chart into k3d with the minimal-footprint values + ingress
	helm upgrade --install $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) --create-namespace \
		-f $(MINIMAL_VALUES) \
		--set mcp.ingress.enabled=true \
		--set-string mcp.ingress.className=traefik \
		--set 'mcp.ingress.hosts[0].host=$(MCP_HOST)' \
		--set 'mcp.ingress.hosts[0].paths[0].path=/' \
		--set 'mcp.ingress.hosts[0].paths[0].pathType=Prefix' \
		--wait --timeout 10m

.PHONY: k3d-test
k3d-test: ## Full end-to-end: create cluster, deploy, and helm test
	$(MAKE) k3d-up
	$(MAKE) k3d-deploy
	@echo "Waiting for the API and MCP server to be ready..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(RELEASE_NAME)-firecrawl-mcp-api --timeout=300s
	kubectl -n $(NAMESPACE) rollout status deploy/$(RELEASE_NAME)-firecrawl-mcp-mcp --timeout=120s
	@echo "Running helm test (API readiness + MCP initialize handshake)..."
	helm test $(RELEASE_NAME) -n $(NAMESPACE) --timeout 150s

.PHONY: clean
clean: ## Remove packaged charts
	rm -f *.tgz
