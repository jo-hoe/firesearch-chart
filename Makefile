# Firesearch — self-hosted deployment
#
# Common targets for building the image, linting/packaging the Helm chart, and
# spinning up a local k3d cluster for end-to-end testing.

# ── Configuration (override on the command line, e.g. `make build TAG=1.2.3`) ──
IMAGE_NAME    ?= firesearch
TAG           ?= local
# Firesearch git ref (tag/branch/sha) the image is built from. Defaults to TAG
# when TAG looks like a version, else `main`.
FIRESEARCH_REF ?= main
CHART_DIR     ?= charts/firesearch
RELEASE_NAME  ?= firesearch
NAMESPACE     ?= firesearch

# k3d specifics
K3D_CLUSTER   ?= firesearch
K3D_CONFIG    ?= k3d/cluster.yaml
# Registry as seen from the host (localhost) and from inside the cluster.
REGISTRY_HOST ?= localhost:5000
REGISTRY_IN   ?= firesearch-registry:5000
# Local values file used for k3d deploys (git-ignored; contains secrets).
LOCAL_VALUES  ?= k3d/values.local.yaml

.DEFAULT_GOAL := help

# ── Meta ──────────────────────────────────────────────────────────────────────
.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

# ── Docker ──────────────────────────────────────────────────────────────────
.PHONY: build
build: ## Build the container image (FIRESEARCH_REF selects the app version)
	docker build --build-arg FIRESEARCH_REF=$(FIRESEARCH_REF) -t $(IMAGE_NAME):$(TAG) .

.PHONY: run
run: ## Run the image locally on :3000 (requires OPENAI_API_KEY, FIRECRAWL_API_KEY in env)
	docker run --rm -p 3000:3000 \
		-e OPENAI_API_KEY=$(OPENAI_API_KEY) \
		-e OPENAI_BASE_URL=$(OPENAI_BASE_URL) \
		-e FIRECRAWL_API_KEY=$(FIRECRAWL_API_KEY) \
		$(IMAGE_NAME):$(TAG)

# ── Helm ──────────────────────────────────────────────────────────────────────
.PHONY: lint
lint: ## Lint the Helm chart
	helm lint $(CHART_DIR) --strict

.PHONY: template
template: ## Render the chart to stdout (uses dummy secrets)
	helm template $(RELEASE_NAME) $(CHART_DIR) \
		--set-string secrets.openaiApiKey=dummy \
		--set-string secrets.firecrawlApiKey=dummy

.PHONY: package
package: ## Package the chart into a .tgz
	helm package $(CHART_DIR)

# ── k3d end-to-end ────────────────────────────────────────────────────────────
.PHONY: k3d-up
k3d-up: ## Create the local k3d cluster (with registry + ingress)
	k3d cluster create --config $(K3D_CONFIG)

.PHONY: k3d-down
k3d-down: ## Delete the local k3d cluster
	k3d cluster delete $(K3D_CLUSTER)

.PHONY: k3d-push
k3d-push: build ## Build and push the image to the k3d registry
	docker tag $(IMAGE_NAME):$(TAG) $(REGISTRY_HOST)/$(IMAGE_NAME):$(TAG)
	docker push $(REGISTRY_HOST)/$(IMAGE_NAME):$(TAG)

.PHONY: k3d-deploy
k3d-deploy: k3d-push ## Deploy the chart into k3d using $(LOCAL_VALUES)
	@test -f $(LOCAL_VALUES) || { \
		echo "ERROR: $(LOCAL_VALUES) not found. Copy k3d/values.example.yaml to it and fill in API keys."; \
		exit 1; }
	helm upgrade --install $(RELEASE_NAME) $(CHART_DIR) \
		--namespace $(NAMESPACE) --create-namespace \
		--set-string image.repository=$(REGISTRY_IN)/$(IMAGE_NAME) \
		--set-string image.tag=$(TAG) \
		-f $(LOCAL_VALUES) \
		--wait --timeout 5m

.PHONY: k3d-test
k3d-test: ## Full end-to-end: create cluster, deploy, and smoke-test
	$(MAKE) k3d-up
	$(MAKE) k3d-deploy
	@echo "Waiting for rollout..."
	kubectl -n $(NAMESPACE) rollout status deploy/$(RELEASE_NAME) --timeout=180s
	@echo "Smoke-testing via port-forward..."
	kubectl -n $(NAMESPACE) port-forward svc/$(RELEASE_NAME) 3000:80 & \
		PF_PID=$$!; sleep 5; \
		curl -fsS http://127.0.0.1:3000/ >/dev/null && echo "OK: app responded" || (echo "FAIL"; kill $$PF_PID; exit 1); \
		kill $$PF_PID

.PHONY: clean
clean: ## Remove packaged charts and build output
	rm -f *.tgz
	rm -rf .next node_modules
