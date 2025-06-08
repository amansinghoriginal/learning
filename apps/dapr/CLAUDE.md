# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dapr-based microservices e-commerce demo application consisting of four Python/FastAPI services:
- **customers**: Customer management with loyalty tiers
- **orders**: Order processing and status management  
- **products**: Product catalog management
- **reviews**: Product review system

Each service uses Dapr for state management and service-to-service communication, with PostgreSQL as the backing state store.

## Common Development Commands

### Build Commands
```bash
# Build individual services
make build-customers
make build-orders
make build-products
make build-reviews

# Build all services
make build-all
```

### Deployment Commands
```bash
# Complete setup (create cluster, install Dapr, build and deploy all)
make quickstart

# Deploy individual services with infrastructure
make deploy-customers
make deploy-orders
make deploy-products
make deploy-reviews

# Deploy all services
make deploy-all

# Redeploy services (without infrastructure)
make redeploy-customers
make redeploy-orders
make redeploy-products
make redeploy-reviews
```

### Testing Commands
```bash
# Load initial test data
make load-customers-data
make load-orders-data
make load-products-data
make load-reviews-data

# Run API tests
make test-customers-apis
make test-orders-apis
make test-products-apis
make test-reviews-apis

# Port forward to access services locally
make port-forward
```

### Debugging Commands
```bash
# View logs
make logs-customers
make logs-orders
make logs-products
make logs-reviews

# Check status
make status

# Get pod information
make get-pods
```

## Architecture Notes

### Service Structure
Each service follows identical patterns:
- `code/main.py`: FastAPI application with REST endpoints
- `code/models.py`: Pydantic data models
- `code/dapr_client.py`: Dapr client wrapper for state management
- `k8s/deployment.yaml`: Kubernetes deployment with Dapr sidecar
- `k8s/dapr/statestore.yaml`: Dapr state store configuration
- `k8s/postgres/postgres.yaml`: PostgreSQL database deployment

### Key Patterns
1. **State Management**: All state operations go through Dapr's state API, not direct database access
2. **Service Discovery**: Services communicate via Dapr's service invocation
3. **Configuration**: Each service has its own PostgreSQL instance configured as a Dapr state store
4. **Testing**: Shell scripts in `setup/` directories handle data loading and API testing

### Important Files
- `/Makefile`: Central command orchestration - always check here first for available commands
- `/services/common/setup/common-utils.sh`: Shared utilities for testing scripts
- Service endpoints are exposed on ports 31001-31004 when using `make port-forward`

## Development Workflow

1. Make changes to service code in `/services/{service-name}/code/`
2. Build the service: `make build-{service-name}`
3. Redeploy: `make redeploy-{service-name}`
4. Test: `make test-{service-name}-apis`
5. Check logs if needed: `make logs-{service-name}`

## Drasi Integration

The `/drasi/` directory contains query and reaction configurations for event-driven data processing. These YAML files define continuous queries over the service data but are not part of the core service functionality.