.DEFAULT_GOAL := help
.PHONY: help kind-up kind-down bootstrap status password ui sync validate seal set-repo cleanup

CLUSTER ?= argocd-gitops
KUSTOMIZE_DIRS := bootstrap projects apps platform/sealed-secrets workloads/hello-app

help: ## Show this help
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

kind-up: ## Create a local kind cluster for testing
	kind create cluster --name $(CLUSTER)

kind-down: ## Delete the local kind cluster
	kind delete cluster --name $(CLUSTER)

bootstrap: ## Install Argo CD and the root app (run once per cluster)
	@./scripts/bootstrap.sh

status: ## List Argo CD applications
	@kubectl -n argocd get applications

password: ## Print the initial admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

ui: ## Open the Argo CD UI on http://localhost:8080 (Ctrl+C to stop)
	kubectl -n argocd port-forward svc/argocd-server 8080:80

sync: ## Ask Argo CD to refresh the root app from Git now
	@kubectl -n argocd annotate application root argocd.argoproj.io/refresh=normal --overwrite

validate: ## Render every kustomization and check it against Kubernetes schemas
	@for dir in $(KUSTOMIZE_DIRS); do \
		echo "==> $$dir"; \
		kustomize build $$dir | kubeconform -strict -summary -skip CustomResourceDefinition \
			-schema-location default \
			-schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
			|| exit 1; \
	done

seal: ## Seal a secret: make seal NS=app-hello NAME=hello-app-secret DATA="KEY=value"
	@./scripts/seal-secret.sh $(NS) $(NAME) $(DATA)

set-repo: ## Point all apps at your fork: make set-repo REPO=https://github.com/<you>/argocd-gitops.git
	@./scripts/set-repo.sh $(REPO)

cleanup: ## Remove all apps and Argo CD from the current cluster
	@./scripts/cleanup.sh
