# Dapr Microservices Architecture Summary

## Overview

This project implements a microservices architecture using Dapr (Distributed Application Runtime) with four core services:
- **Customers Service**: Manages customer information and loyalty tiers
- **Products Service**: Manages product inventory and stock levels
- **Reviews Service**: Handles customer reviews for products
- **Orders Service**: Manages customer orders

All services are built using Python FastAPI and use Dapr state stores backed by PostgreSQL databases.

## Common Architecture Patterns

### Technology Stack
- **Framework**: FastAPI (Python)
- **State Management**: Dapr State Store (PostgreSQL backend)
- **Container Runtime**: Docker
- **Orchestration**: Kubernetes (k3d)
- **Ingress**: Traefik with prefix stripping
- **Service Mesh**: Dapr sidecars

### Code Structure
Each service follows the same pattern:
```
service/
├── code/
│   ├── main.py          # FastAPI application with REST endpoints
│   ├── models.py        # Pydantic models for validation
│   └── dapr_client.py   # Dapr state store wrapper
├── k8s/
│   ├── deployment.yaml  # K8s deployment, service, ingress
│   ├── dapr/
│   │   └── statestore.yaml  # Dapr component configuration
│   └── postgres/
│       └── postgres.yaml    # PostgreSQL StatefulSet
├── setup/
│   ├── load-initial-data.sh  # Data seeding script
│   └── test-apis.sh          # API testing script
├── Dockerfile               # Container definition
└── requirements.txt         # Python dependencies
```

### Common Features
- **Health Check**: All services expose `/health` endpoint
- **CORS**: Enabled for all origins
- **Logging**: Configurable log levels via LOG_LEVEL env var
- **Error Handling**: Consistent HTTP status codes and error messages
- **Dapr Integration**: Each service has a Dapr sidecar for state management
- **Resource Limits**: CPU (500m/100m) and Memory (512Mi/128Mi) limits/requests

## Service Details

### 1. Customers Service

**Purpose**: Manages customer information including loyalty tiers

**Base Path**: `/customers-service`

**API Endpoints**:
- `POST /customers` - Create a new customer
- `GET /customers/{customer_id}` - Get customer details
- `PUT /customers/{customer_id}` - Update customer information
- `DELETE /customers/{customer_id}` - Delete a customer

**Models**:
```python
class LoyaltyTier(Enum):
    BRONZE = "BRONZE"
    SILVER = "SILVER"
    GOLD = "GOLD"

class CustomerItem:
    customerId: int
    customerName: str
    loyaltyTier: LoyaltyTier
    email: str

class CustomerCreateRequest:
    customerId: Optional[int]  # Auto-generated if not provided
    customerName: str
    email: str
    loyaltyTier: LoyaltyTier = LoyaltyTier.BRONZE

class CustomerUpdateRequest:
    customerName: Optional[str]
    loyaltyTier: Optional[LoyaltyTier]
    email: Optional[str]
```

**Dapr Configuration**:
- App ID: `customers`
- State Store: `customers-store`
- Database: PostgreSQL (`customers-db`)

### 2. Products Service

**Purpose**: Manages product inventory and stock levels

**Base Path**: `/products-service`

**API Endpoints**:
- `POST /products` - Create or update product
- `GET /products/{product_id}` - Get product details
- `PUT /products/{product_id}/decrement` - Decrease stock
- `PUT /products/{product_id}/increment` - Increase stock
- `DELETE /products/{product_id}` - Delete a product

**Models**:
```python
class ProductItem:
    productId: int
    productName: str
    productDescription: str
    stockOnHand: int
    lowStockThreshold: int

class ProductCreateRequest:
    productId: int
    productName: str
    productDescription: str
    stockOnHand: int
    lowStockThreshold: int

class StockUpdateRequest:
    quantity: int  # Must be > 0

class ProductResponse:
    # Includes all ProductItem fields plus:
    isLowStock: bool  # Calculated field
```

**Dapr Configuration**:
- App ID: `products`
- State Store: `products-store`
- Database: PostgreSQL (`products-db`)

### 3. Reviews Service

**Purpose**: Handles customer reviews for products

**Base Path**: `/reviews-service`

**API Endpoints**:
- `POST /reviews` - Submit a new review
- `GET /reviews/{review_id}` - Get review details
- `PUT /reviews/{review_id}` - Update a review
- `DELETE /reviews/{review_id}` - Delete a review

**Models**:
```python
class ReviewItem:
    reviewId: int
    productId: int
    customerId: int
    rating: int  # 1-5
    reviewText: Optional[str] = ""

class ReviewCreateRequest:
    reviewId: Optional[int]  # Auto-generated if not provided
    productId: int
    customerId: int
    rating: int  # 1-5
    reviewText: Optional[str]

class ReviewUpdateRequest:
    rating: Optional[int]  # 1-5
    reviewText: Optional[str]
```

**Dapr Configuration**:
- App ID: `reviews`
- State Store: `reviews-store`
- Database: PostgreSQL (`reviews-db`)

### 4. Orders Service

**Purpose**: Manages customer orders with multiple items

**Base Path**: `/orders-service`

**API Endpoints**:
- `POST /orders` - Create a new order
- `GET /orders/{order_id}` - Get order details
- `PUT /orders/{order_id}/status` - Update order status
- `DELETE /orders/{order_id}` - Delete an order

**Models**:
```python
class OrderStatus(Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    PROCESSING = "PROCESSING"
    SHIPPED = "SHIPPED"
    DELIVERED = "DELIVERED"
    CANCELLED = "CANCELLED"

class OrderItem:
    productId: int
    quantity: int

class Order:
    orderId: int
    customerId: int
    items: List[OrderItem]
    status: OrderStatus

class OrderCreateRequest:
    orderId: Optional[int]  # Auto-generated if not provided
    customerId: int
    items: List[OrderItemRequest]  # Min 1 item, no duplicates

class OrderStatusUpdateRequest:
    status: OrderStatus
```

**Business Rules**:
- Cannot change status of delivered orders
- Cannot change status of cancelled orders
- Order items must have unique product IDs

**Dapr Configuration**:
- App ID: `orders`
- State Store: `orders-store`
- Database: PostgreSQL (`orders-db`)

## Deployment Architecture

### Kubernetes Resources

Each service deploys:
1. **Deployment**: Single replica with Dapr annotations
2. **Service**: ClusterIP service on port 80
3. **Middleware**: Traefik StripPrefix middleware
4. **Ingress**: Path-based routing with prefix stripping
5. **StatefulSet**: PostgreSQL database with persistent storage
6. **PVC**: 1Gi persistent volume for database data
7. **Dapr Component**: State store configuration

### Ingress Configuration

The services use Traefik ingress with prefix stripping:
- External path: `/customers-service/*`
- Internal path: `/*` (prefix stripped)
- Middleware: `{service}-stripprefix`

This allows accessing services via:
- `POST localhost/customers-service/customers`
- `GET localhost/products-service/products/123`
- etc.

The FastAPI apps are configured with `root_path` matching the external path for proper OpenAPI documentation.

### Dapr Integration

Each service has Dapr sidecar injection enabled via annotations:
```yaml
dapr.io/enabled: "true"
dapr.io/app-id: "{service-name}"
dapr.io/app-port: "8000"
dapr.io/enable-api-logging: "true"
dapr.io/log-level: "info"
```

State stores use PostgreSQL with configuration:
- Connection to service-specific database
- Table name matches service name
- No key prefix (`keyPrefix: "none"`)
- Not used for actors (`actorStateStore: "false"`)

## Makefile Commands

### Setup & Teardown
- `make setup` - Create cluster and install Dapr
- `make teardown` - Remove everything including data
- `make quickstart` - Complete setup, build, and deploy

### Build Commands
- `make build-{service}` - Build individual service
- `make build-all` - Build all services

### Deploy Commands
- `make deploy-{service}` - Deploy service with infrastructure
- `make deploy-{service}-infra` - Deploy only infrastructure
- `make deploy-all` - Deploy everything
- `make redeploy-{service}` - Redeploy service (not infra)

### Clean Commands
- `make clean-{service}` - Remove service (keeps data)
- `make deep-clean-{service}` - Remove service and data
- `make clean-all` - Clean all services
- `make deep-clean-all` - Deep clean everything

### Utility Commands
- `make status` - Show deployment status
- `make logs-{service}` - Follow service logs
- `make port-forward` - Access services locally
- `make load-{service}-data` - Load initial data
- `make test-{service}-apis` - Test service APIs

### Development Workflow
- `make rebuild-redeploy-{service}` - Rebuild and redeploy a service

## Data Persistence

- Each service has its own PostgreSQL instance
- Data persists in PVCs even when services are deleted
- Use `deep-clean` commands to remove persistent data
- State store operations are synchronous via Dapr client

## Common Patterns

### ID Generation
- All services accept optional IDs in create requests
- Auto-generate random IDs if not provided
- Check for ID uniqueness before creation

### Error Handling
- 400: Bad request (validation, duplicates)
- 404: Resource not found
- 500: Internal server errors
- 503: Service unavailable (state store not ready)

### Data Format Conversion
- API uses camelCase (FastAPI models)
- Database uses snake_case (PostgreSQL convention)
- Models have `to_db_dict()` and `from_db_dict()` methods

### Performance Monitoring
- All operations log execution time in milliseconds
- Structured logging with configurable levels
- Health checks for liveness and readiness probes