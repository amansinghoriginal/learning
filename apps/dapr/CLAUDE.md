# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dapr-based microservices e-commerce application with real-time monitoring capabilities powered by Drasi. The system demonstrates modern cloud-native patterns including service mesh, distributed state management, and real-time data change processing.

## Common Development Commands

### Quick Start
```bash
# Complete setup, build, and deploy everything
make quickstart

# Show all available commands
make help
```

### Cluster Management
```bash
# Setup k3d cluster with Dapr
make setup

# Teardown everything
make teardown

# Check status of all services
make status
```

### Building Services
```bash
# Build all services
make build-all

# Build individual services
make build-customers
make build-orders
make build-products
make build-reviews
make build-dashboard
```

### Deployment
```bash
# Deploy all services with infrastructure
make deploy-all

# Deploy only dashboard infrastructure (SignalR ingress)
make deploy-dashboard-infra

# Deploy individual services
make deploy-customers
make deploy-orders
make deploy-products
make deploy-reviews
make deploy-dashboard

# Redeploy service (keeps infrastructure)
make redeploy-customers
make redeploy-orders
make redeploy-products
make redeploy-reviews
make redeploy-dashboard
```

### Development Access
```bash
# Port forward to access services locally
make port-forward
# Services available at:
# - Customers: http://localhost:8001/customers-service
# - Orders: http://localhost:8001/orders-service
# - Products: http://localhost:8001/products-service
# - Reviews: http://localhost:8001/reviews-service
# - Dashboard: http://localhost:8001/dashboard
```

### Testing and Data Loading
```bash
# Load initial data
make load-all-data

# Test APIs
make test-all-apis

# View logs
make logs-customers
make logs-orders
make logs-products
make logs-reviews
make logs-dashboard
```

### Dashboard Development
```bash
cd services/dashboard
npm install
npm start          # Development server on port 3000
npm run build      # Production build
npm run preview    # Preview production build
```

## Architecture Overview

### Microservices Structure

Each service (`customers`, `orders`, `products`, `reviews`) follows the same pattern:
- **Python/FastAPI** backend with consistent API structure
- **PostgreSQL** database per service with Dapr state store abstraction
- **Kubernetes** deployments with Dapr sidecar injection
- Isolated namespaces and database-per-service pattern

### Drasi Integration

Drasi provides real-time monitoring by:
1. **Sources** connect to each service's PostgreSQL database to capture changes
2. **Continuous Queries** detect complex business conditions:
   - `at-risk-orders` - Orders where stock quantity < order quantity
   - `delayed-gold-orders` - Gold tier customers with orders stuck in processing
3. **SignalR Reaction** broadcasts query results to the dashboard in real-time

The dashboard receives these updates without polling, showing:
- **Stock Risk View** - Orders at risk due to insufficient inventory
- **Gold Customer Delays View** - High-value customers experiencing delays

### Key Technologies

- **Dapr** - Distributed application runtime for service communication and state management
- **Drasi** - Data change processing platform for real-time monitoring
- **k3d** - Lightweight Kubernetes for local development
- **Traefik** - Ingress controller for routing
- **SignalR** - Real-time communication protocol for dashboard updates

### Development Patterns

1. **Service Communication**: Services communicate through Dapr's service invocation
2. **State Management**: Each service uses Dapr state store backed by PostgreSQL
3. **Real-time Updates**: Drasi continuous queries + SignalR for push-based updates
4. **Infrastructure as Code**: All configurations in Kubernetes YAML manifests
5. **Developer Experience**: Comprehensive Makefile for common operations

When modifying services, ensure:
- API changes maintain compatibility with Drasi queries
- Database schema changes are reflected in Drasi source configurations
- New business monitoring needs are implemented as Drasi continuous queries
- Dashboard components properly handle SignalR connection lifecycle