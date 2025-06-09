SHELL := /bin/bash
CLUSTER_NAME := dapr-demo

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ==================== Cluster Management ====================

.PHONY: create-cluster
create-cluster: ## Create k3d cluster
	@echo -e "$(GREEN)Creating k3d cluster...$(NC)"
	k3d cluster create $(CLUSTER_NAME) \
		--api-port 6550 \
		--port "80:80@loadbalancer" \
		--port "443:443@loadbalancer" \
		--agents 0
	@echo -e "$(GREEN)Waiting for cluster to be ready...$(NC)"
	kubectl wait --for=condition=Ready nodes --all --timeout=60s
	@echo -e "$(GREEN)Cluster created successfully!$(NC)"

.PHONY: delete-cluster
delete-cluster: ## Delete k3d cluster
	@echo -e "$(RED)Deleting k3d cluster...$(NC)"
	k3d cluster delete $(CLUSTER_NAME)
	@echo -e "$(GREEN)Cluster deleted successfully!$(NC)"

.PHONY: install-dapr
install-dapr: ## Install Dapr on the cluster
	@echo -e "$(GREEN)Installing Dapr on Kubernetes...$(NC)"
	dapr init -k --wait
	@echo -e "$(GREEN)Waiting for Dapr to be ready...$(NC)"
	kubectl wait --for=condition=Ready pods --all -n dapr-system --timeout=300s
	@echo -e "$(GREEN)Dapr installed successfully!$(NC)"

.PHONY: uninstall-dapr
uninstall-dapr: ## Uninstall Dapr from the cluster
	@echo -e "$(RED)Uninstalling Dapr...$(NC)"
	dapr uninstall -k --all
	@echo -e "$(GREEN)Dapr uninstalled successfully!$(NC)"

# ==================== Service Build Commands ====================

.PHONY: build-customers
build-customers: ## Build customers service Docker image
	@echo -e "$(GREEN)Building customers service...$(NC)"
	cd services/customers && \
	docker build -t customers:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import customers:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)customers service built and imported!$(NC)"

.PHONY: build-orders
build-orders: ## Build orders service Docker image
	@echo -e "$(GREEN)Building orders service...$(NC)"
	cd services/orders && \
	docker build -t orders:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import orders:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)Orders service built and imported!$(NC)"

.PHONY: build-products
build-products: ## Build products service Docker image
	@echo -e "$(GREEN)Building products service...$(NC)"
	cd services/products && \
	docker build -t products:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import products:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)products service built and imported!$(NC)"

.PHONY: build-reviews
build-reviews: ## Build reviews service Docker image
	@echo -e "$(GREEN)Building reviews service...$(NC)"
	cd services/reviews && \
	docker build -t reviews:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import reviews:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)Reviews service built and imported!$(NC)"

.PHONY: build-dashboard
build-dashboard: ## Build dashboard service Docker image
	@echo -e "$(GREEN)Building dashboard service...$(NC)"
	cd services/dashboard && \
	docker build -t dashboard:latest .
	@echo -e "$(YELLOW)Importing image to k3d cluster...$(NC)"
	k3d image import dashboard:latest -c $(CLUSTER_NAME)
	@echo -e "$(GREEN)Dashboard service built and imported!$(NC)"

.PHONY: build-all
build-all: build-customers build-orders build-products build-reviews build-dashboard ## Build all service Docker images

# ==================== Service Deployment Commands ====================

.PHONY: deploy-customers-infra
deploy-customers-infra: ## Deploy customers service infrastructure (PostgreSQL + Dapr components)
	@echo -e "$(GREEN)Deploying customers PostgreSQL...$(NC)"
	kubectl apply -f services/customers/k8s/postgres/postgres.yaml
	@echo -e "$(YELLOW)Waiting for customers-db to be ready...$(NC)"
	kubectl rollout status statefulset/customers-db --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=customers-db --timeout=300s
	@echo -e "$(GREEN)Deploying customers Dapr components...$(NC)"
	kubectl apply -f services/customers/k8s/dapr/statestore.yaml
	@echo -e "$(GREEN)customers infrastructure deployed!$(NC)"

.PHONY: deploy-customers
deploy-customers: deploy-customers-infra ## Deploy customers service (infra + service)
	@echo -e "$(GREEN)Deploying customers service...$(NC)"
	kubectl apply -f services/customers/k8s/deployment.yaml
	kubectl rollout status deployment/customers --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=customers --timeout=300s
	@echo -e "$(GREEN)customers service deployed successfully!$(NC)"

.PHONY: deploy-orders-infra
deploy-orders-infra: ## Deploy orders service infrastructure (PostgreSQL + Dapr components)
	@echo -e "$(GREEN)Deploying orders PostgreSQL...$(NC)"
	kubectl apply -f services/orders/k8s/postgres/postgres.yaml
	@echo -e "$(YELLOW)Waiting for orders-db to be ready...$(NC)"
	kubectl rollout status statefulset/orders-db --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=orders-db --timeout=300s
	@echo -e "$(GREEN)Deploying orders Dapr components...$(NC)"
	kubectl apply -f services/orders/k8s/dapr/statestore.yaml
	@echo -e "$(GREEN)Orders infrastructure deployed!$(NC)"

.PHONY: deploy-orders
deploy-orders: deploy-orders-infra ## Deploy orders service (infra + service)
	@echo -e "$(GREEN)Deploying orders service...$(NC)"
	kubectl apply -f services/orders/k8s/deployment.yaml
	kubectl rollout status deployment/orders --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=orders --timeout=300s
	@echo -e "$(GREEN)Orders service deployed successfully!$(NC)"

.PHONY: deploy-products-infra
deploy-products-infra: ## Deploy products service infrastructure (PostgreSQL + Dapr components)
	@echo -e "$(GREEN)Deploying products PostgreSQL...$(NC)"
	kubectl apply -f services/products/k8s/postgres/postgres.yaml
	@echo -e "$(YELLOW)Waiting for products-db to be ready...$(NC)"
	kubectl rollout status statefulset/products-db --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=products-db --timeout=300s
	@echo -e "$(GREEN)Deploying products Dapr components...$(NC)"
	kubectl apply -f services/products/k8s/dapr/statestore.yaml
	@echo -e "$(GREEN)products infrastructure deployed!$(NC)"

.PHONY: deploy-products
deploy-products: deploy-products-infra ## Deploy products service (infra + service)
	@echo -e "$(GREEN)Deploying products service...$(NC)"
	kubectl apply -f services/products/k8s/deployment.yaml
	kubectl rollout status deployment/products --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=products --timeout=300s
	@echo -e "$(GREEN)products service deployed successfully!$(NC)"

.PHONY: deploy-reviews-infra
deploy-reviews-infra: ## Deploy reviews service infrastructure (PostgreSQL + Dapr components)
	@echo -e "$(GREEN)Deploying reviews PostgreSQL...$(NC)"
	kubectl apply -f services/reviews/k8s/postgres/postgres.yaml
	@echo -e "$(YELLOW)Waiting for reviews-db to be ready...$(NC)"
	kubectl rollout status statefulset/reviews-db --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=reviews-db --timeout=300s
	@echo -e "$(GREEN)Deploying reviews Dapr components...$(NC)"
	kubectl apply -f services/reviews/k8s/dapr/statestore.yaml
	@echo -e "$(GREEN)Reviews infrastructure deployed!$(NC)"

.PHONY: deploy-reviews
deploy-reviews: deploy-reviews-infra ## Deploy reviews service (infra + service)
	@echo -e "$(GREEN)Deploying reviews service...$(NC)"
	kubectl apply -f services/reviews/k8s/deployment.yaml
	kubectl rollout status deployment/reviews --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=reviews --timeout=300s
	@echo -e "$(GREEN)Reviews service deployed successfully!$(NC)"

.PHONY: deploy-dashboard-infra
deploy-dashboard-infra: ## Deploy dashboard infrastructure (SignalR ingress)
	@echo -e "$(GREEN)Deploying SignalR ingress for dashboard...$(NC)"
	kubectl apply -f services/dashboard/k8s/signalr-ingress.yaml
	@echo -e "$(GREEN)Dashboard infrastructure deployed!$(NC)"

.PHONY: deploy-dashboard
deploy-dashboard: deploy-dashboard-infra ## Deploy dashboard service (infra + service)
	@echo -e "$(GREEN)Deploying dashboard service...$(NC)"
	kubectl apply -f services/dashboard/k8s/deployment.yaml
	kubectl rollout status deployment/dashboard --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=dashboard --timeout=300s
	@echo -e "$(GREEN)Dashboard service deployed successfully!$(NC)"

.PHONY: deploy-all
deploy-all: deploy-customers deploy-orders deploy-products deploy-reviews deploy-dashboard ## Deploy all services with infrastructure

# ==================== Service Redeploy Commands ====================

.PHONY: redeploy-customers
redeploy-customers: ## Redeploy customers service (service only, not infra)
	@echo -e "$(YELLOW)Redeploying customers service...$(NC)"
	kubectl delete -f services/customers/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/customers/k8s/deployment.yaml
	kubectl rollout status deployment/customers --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=customers --timeout=300s
	@echo -e "$(GREEN)customers service redeployed!$(NC)"

.PHONY: redeploy-orders
redeploy-orders: ## Redeploy orders service (service only, not infra)
	@echo -e "$(YELLOW)Redeploying orders service...$(NC)"
	kubectl delete -f services/orders/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/orders/k8s/deployment.yaml
	kubectl rollout status deployment/orders --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=orders --timeout=300s
	@echo -e "$(GREEN)Orders service redeployed!$(NC)"

.PHONY: redeploy-products
redeploy-products: ## Redeploy products service (service only, not infra)
	@echo -e "$(YELLOW)Redeploying products service...$(NC)"
	kubectl delete -f services/products/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/products/k8s/deployment.yaml
	kubectl rollout status deployment/products --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=products --timeout=300s
	@echo -e "$(GREEN)products service redeployed!$(NC)"

.PHONY: redeploy-reviews
redeploy-reviews: ## Redeploy reviews service (service only, not infra)
	@echo -e "$(YELLOW)Redeploying reviews service...$(NC)"
	kubectl delete -f services/reviews/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/reviews/k8s/deployment.yaml
	kubectl rollout status deployment/reviews --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=reviews --timeout=300s
	@echo -e "$(GREEN)Reviews service redeployed!$(NC)"

.PHONY: redeploy-dashboard
redeploy-dashboard: ## Redeploy dashboard service
	@echo -e "$(YELLOW)Redeploying dashboard service...$(NC)"
	kubectl delete -f services/dashboard/k8s/deployment.yaml --ignore-not-found=true
	kubectl apply -f services/dashboard/k8s/deployment.yaml
	kubectl rollout status deployment/dashboard --timeout=300s
	kubectl wait --for=condition=Ready pod -l app=dashboard --timeout=300s
	@echo -e "$(GREEN)Dashboard service redeployed!$(NC)"

# ==================== Service Clean Commands ====================

.PHONY: clean-customers
clean-customers: ## Clean customers service and infrastructure (keeps data)
	@echo -e "$(RED)Cleaning customers service...$(NC)"
	-kubectl delete -f services/customers/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/customers/k8s/dapr/statestore.yaml --ignore-not-found=true
	-kubectl delete -f services/customers/k8s/postgres/postgres.yaml --ignore-not-found=true
	@echo -e "$(GREEN)customers service cleaned!$(NC)"

.PHONY: clean-orders
clean-orders: ## Clean orders service and infrastructure (keeps data)
	@echo -e "$(RED)Cleaning orders service...$(NC)"
	-kubectl delete -f services/orders/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/orders/k8s/dapr/statestore.yaml --ignore-not-found=true
	-kubectl delete -f services/orders/k8s/postgres/postgres.yaml --ignore-not-found=true
	@echo -e "$(GREEN)Orders service cleaned!$(NC)"

.PHONY: clean-products
clean-products: ## Clean products service and infrastructure (keeps data)
	@echo -e "$(RED)Cleaning products service...$(NC)"
	-kubectl delete -f services/products/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/products/k8s/dapr/statestore.yaml --ignore-not-found=true
	-kubectl delete -f services/products/k8s/postgres/postgres.yaml --ignore-not-found=true
	@echo -e "$(GREEN)products service cleaned!$(NC)"

.PHONY: clean-reviews
clean-reviews: ## Clean reviews service and infrastructure (keeps data)
	@echo -e "$(RED)Cleaning reviews service...$(NC)"
	-kubectl delete -f services/reviews/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/reviews/k8s/dapr/statestore.yaml --ignore-not-found=true
	-kubectl delete -f services/reviews/k8s/postgres/postgres.yaml --ignore-not-found=true
	@echo -e "$(GREEN)Reviews service cleaned!$(NC)"

.PHONY: clean-dashboard
clean-dashboard: ## Clean dashboard service and infrastructure
	@echo -e "$(RED)Cleaning dashboard service...$(NC)"
	-kubectl delete -f services/dashboard/k8s/deployment.yaml --ignore-not-found=true
	-kubectl delete -f services/dashboard/k8s/signalr-ingress.yaml --ignore-not-found=true
	@echo -e "$(GREEN)Dashboard service cleaned!$(NC)"

.PHONY: clean-all
clean-all: clean-customers clean-orders clean-products clean-reviews clean-dashboard ## Clean all services and infrastructure

# ==================== Deep Clean Commands (removes persistent data) ====================

.PHONY: deep-clean-customers
deep-clean-customers: clean-customers ## Deep clean customers service (removes all data)
	@echo -e "$(RED)Deep cleaning customers service data...$(NC)"
	-kubectl delete pvc customers-db-data-customers-db-0 --ignore-not-found=true
	@echo -e "$(GREEN)customers service deep cleaned!$(NC)"

.PHONY: deep-clean-orders
deep-clean-orders: clean-orders ## Deep clean orders service (removes all data)
	@echo -e "$(RED)Deep cleaning orders service data...$(NC)"
	-kubectl delete pvc orders-db-data-orders-db-0 --ignore-not-found=true
	@echo -e "$(GREEN)Orders service deep cleaned!$(NC)"

.PHONY: deep-clean-products
deep-clean-products: clean-products ## Deep clean products service (removes all data)
	@echo -e "$(RED)Deep cleaning products service data...$(NC)"
	-kubectl delete pvc products-db-data-products-db-0 --ignore-not-found=true
	@echo -e "$(GREEN)products service deep cleaned!$(NC)"

.PHONY: deep-clean-reviews
deep-clean-reviews: clean-reviews ## Deep clean reviews service (removes all data)
	@echo -e "$(RED)Deep cleaning reviews service data...$(NC)"
	-kubectl delete pvc reviews-db-data-reviews-db-0 --ignore-not-found=true
	@echo -e "$(GREEN)Reviews service deep cleaned!$(NC)"

.PHONY: deep-clean-all
deep-clean-all: deep-clean-customers deep-clean-orders deep-clean-products deep-clean-reviews ## Deep clean all services (removes all data)

# ==================== Utility Commands ====================

.PHONY: setup
setup: create-cluster install-dapr ## Complete setup: create cluster and install Dapr

.PHONY: teardown
teardown: deep-clean-all uninstall-dapr delete-cluster ## Complete teardown: remove everything

.PHONY: status
status: ## Show status of all services and databases
	@echo -e "$(GREEN)=== Cluster Nodes ===$(NC)"
	kubectl get nodes
	@echo -e "\n$(GREEN)=== Dapr Status ===$(NC)"
	dapr status -k
	@echo -e "\n$(GREEN)=== PostgreSQL Databases ===$(NC)"
	kubectl get statefulsets | grep -E "(customers|orders|products|reviews)-db" || echo "No databases found"
	@echo -e "\n$(GREEN)=== Services ===$(NC)"
	kubectl get pods | grep -E "^(customers|orders|products|reviews)-" || echo "No services found"
	@echo -e "\n$(GREEN)=== Persistent Volumes ===$(NC)"
	kubectl get pvc | grep -E "(customers|orders|products|reviews)-db-data" || echo "No PVCs found"

.PHONY: logs-customers
logs-customers: ## Show logs for customers service
	kubectl logs -l app=customers -f

.PHONY: logs-orders
logs-orders: ## Show logs for orders service
	kubectl logs -l app=orders -f

.PHONY: logs-products
logs-products: ## Show logs for products service
	kubectl logs -l app=products -f

.PHONY: logs-reviews
logs-reviews: ## Show logs for reviews service
	kubectl logs -l app=reviews -f

.PHONY: logs-dashboard
logs-dashboard: ## Show logs for dashboard service
	kubectl logs -l app=dashboard -f

.PHONY: port-forward
port-forward: ## Port forward to access services locally (Ctrl+C to stop)
	@echo -e "$(GREEN)Starting port forwarding...$(NC)"
	@echo -e "$(YELLOW)Access services at:$(NC)"
	@echo -e "  customers: http://localhost:8001/customers-service"
	@echo -e "  Orders:   http://localhost:8001/orders-service"
	@echo -e "  products:  http://localhost:8001/products-service"
	@echo -e "  Reviews:  http://localhost:8001/reviews-service"
	@echo -e "  Dashboard: http://localhost:8001/dashboard"
	@echo -e "$(YELLOW)Press Ctrl+C to stop$(NC)"
	kubectl port-forward svc/traefik -n kube-system 8001:80

# ==================== Quick Start Commands ====================

.PHONY: quickstart
quickstart: setup build-all deploy-all ## Complete quickstart: setup, build, and deploy everything
	@echo -e "$(GREEN)=====================================$(NC)"
	@echo -e "$(GREEN)Dapr microservices deployed!$(NC)"
	@echo -e "$(GREEN)=====================================$(NC)"
	@echo -e "Run 'make status' to check the deployment"
	@echo -e "Run 'make port-forward' to access services locally"

.PHONY: rebuild-redeploy-customers
rebuild-redeploy-customers: build-customers redeploy-customers ## Rebuild and redeploy customers service

.PHONY: rebuild-redeploy-orders
rebuild-redeploy-orders: build-orders redeploy-orders ## Rebuild and redeploy orders service

.PHONY: rebuild-redeploy-products
rebuild-redeploy-products: build-products redeploy-products ## Rebuild and redeploy products service

.PHONY: rebuild-redeploy-reviews
rebuild-redeploy-reviews: build-reviews redeploy-reviews ## Rebuild and redeploy reviews service

.PHONY: rebuild-redeploy-dashboard
rebuild-redeploy-dashboard: build-dashboard redeploy-dashboard ## Rebuild and redeploy dashboard service

# ==================== Service setup Commands ====================

.PHONY: load-customers-data
load-customers-data: ## Load initial customers data
	@echo -e "$(GREEN)Loading initial customers data...$(NC)"
	@cd services/customers/setup && ./load-initial-data.sh

.PHONY: test-customers-apis
test-customers-apis: ## Run basic tests on customers APIs
	@echo -e "$(GREEN)Running customers API tests...$(NC)"
	@cd services/customers/setup && ./test-apis.sh

.PHONY: load-products-data
load-products-data: ## Load initial products data
	@echo -e "$(GREEN)Loading initial products data...$(NC)"
	@cd services/products/setup && ./load-initial-data.sh

.PHONY: test-products-apis
test-products-apis: ## Run basic tests on products APIs
	@echo -e "$(GREEN)Running products API tests...$(NC)"
	@cd services/products/setup && ./test-apis.sh

.PHONY: load-reviews-data
load-reviews-data: ## Load initial review data
	@echo -e "$(GREEN)Loading initial review data...$(NC)"
	@cd services/reviews/setup && ./load-initial-data.sh

.PHONY: test-reviews-apis
test-reviews-apis: ## Run basic tests on reviews APIs
	@echo -e "$(GREEN)Running reviews API tests...$(NC)"
	@cd services/reviews/setup && ./test-apis.sh

.PHONY: load-orders-data
load-orders-data: ## Load initial order data
	@echo -e "$(GREEN)Loading initial order data...$(NC)"
	@cd services/orders/setup && ./load-initial-data.sh

.PHONY: test-orders-apis
test-orders-apis: ## Run basic tests on orders APIs
	@echo -e "$(GREEN)Running orders API tests...$(NC)"
	@cd services/orders/setup && ./test-apis.sh

.PHONY: load-all-data
load-all-data: load-customers-data load-products-data load-reviews-data load-orders-data ## Load initial data for all services

.PHONY: test-all-apis
test-all-apis: test-customers-apis test-products-apis test-reviews-apis test-orders-apis ## Run basic tests on all service APIs