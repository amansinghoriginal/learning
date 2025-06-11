# Drasi Learning Summary

## What is Drasi?

Drasi is a Data Change Processing platform that enables dynamic solutions to detect and react to sophisticated data changes in existing databases and software systems. Unlike traditional change detection that simply reports add/update/delete operations, Drasi uses a query-based approach with rich graph queries to express complex rules about what changes to detect and what data to distribute.

## Core Concepts

### 1. **Sources**
Sources provide connectivity to systems that Drasi observes for changes. They:
- Process change logs/feeds from source systems
- Translate data into a consistent property graph model (nodes and relations)
- Provide query APIs for Continuous Queries to initialize state

**Available Sources:**
- Azure Cosmos DB Gremlin API
- PostgreSQL
- Microsoft SQL Server
- Microsoft Dataverse
- Event Hubs
- Kubernetes

### 2. **Continuous Queries**
The heart of Drasi - queries that run continuously rather than at a point in time. They:
- Written in Cypher Query Language (graph query language)
- Maintain perpetually accurate query results
- Detect precisely which result elements have been added, updated, or deleted
- Can span data across multiple sources without complex joins
- Support temporal functions for time-based logic

**Key Features:**
- Graph-based queries treating all data as nodes and relations
- Support for aggregations, temporal operations, and statistical functions
- Drasi-specific functions like `trueLater()`, `trueFor()`, `trueUntil()` for time-based conditions
- Middleware support for preprocessing data (unwind, map, promote, parse_json, decoder)

**Example Query:**
```cypher
MATCH
  (e:Employee)-[:LOCATED_IN]->(:Building)-[:LOCATED_IN]->(r:Region),
  (i:Incident {type:'environmental'})-[:OCCURS_IN]->(r:Region) 
WHERE
  i.severity IN ['critical', 'extreme'] AND i.endTimeMs IS NULL
RETURN 
  e.name AS EmployeeName, r.name AS RegionName, i.severity AS Severity
```

### 3. **Reactions**
Reactions process the stream of changes from Continuous Queries and take action. They receive notifications about added, updated, and deleted query results.

**Available Reactions:**
- **SignalR**: Real-time web updates
- **SyncDaprStateStore**: Synchronize query results to Dapr state stores
- **PostDaprPubSub**: Publish changes to Dapr pub/sub topics
- **Debug**: Development tool for inspecting query results
- **Azure Event Grid**: Forward changes to Event Grid
- **Gremlin/Dataverse/StoredProc**: Execute commands on databases

## The Three Main Reactions

### 1. SignalR Reaction

**Purpose**: Exposes a SignalR endpoint for real-time web updates

**Key Features:**
- Can host client connections directly or use Azure SignalR Service
- Supports Microsoft Entra authentication
- Provides React and Vue client libraries (@drasi/signalr-react, @drasi/signalr-vue)
- Flattens query results into individual messages per item

**Configuration Example:**
```yaml
kind: Reaction
apiVersion: v1
name: my-signalr-reaction
spec:
  kind: SignalR
  queries:
    query1:
    query2:
  properties:
    connectionString: Endpoint=https://<resource>.service.signalr.net;AccessKey=<key>;Version=1.0;
```

**Output Format:**
```json
{
    "op": "i",  // i=insert, u=update, d=delete
    "ts_ms": 0,
    "payload": {
        "source": {
            "queryId": "query1",
            "ts_ms": 0
        },
        "after": { 
            "id": 10, 
            "temperature": 22 
        }
    }
}
```

**Frontend Integration (React):**
```jsx
import { ResultSet } from '@drasi/signalr-react';

<ResultSet url="http://localhost:8080/hub" queryId="my-query">
  {item => <div>{item.name}</div>}
</ResultSet>
```

### 2. SyncDaprStateStore Reaction

**Purpose**: Materializes Continuous Query results into Dapr state stores for low-latency access

**Use Cases:**
- Simplified Composite API implementation
- Building read models for CQRS
- Providing decoupled data views to microservices
- Improving read performance with pre-computed views

**Key Requirements:**
1. Dapr state store component in application namespace
2. Matching Dapr state store component in drasi-system namespace
3. Both components must have `keyPrefix: "none"` for consistent key access

**Configuration Example:**
```yaml
kind: Reaction
apiVersion: v1
name: state-synchronizer
spec:
  kind: SyncDaprStateStore
  queries:
    orders-ready: '{"stateStoreName": "mystatestore", "keyField": "orderId"}'
    user-profiles: '{"stateStoreName": "profilecache", "keyField": "userId"}'
```

**How It Works:**
1. Performs initial bulk load of query results
2. Incrementally processes changes (adds/updates/deletes)
3. Stores each result item using the specified keyField
4. Microservices access data via standard Dapr state API

### 3. PostDaprPubSub Reaction

**Purpose**: Forwards query changes to Dapr pub/sub topics as CloudEvents

**Use Cases:**
- Decoupled event-driven architectures
- Triggering Dapr workflows and actors
- Building resilient data pipelines
- Real-time notifications to multiple subscribers

**Configuration Example:**
```yaml
kind: Reaction
apiVersion: v1
name: event-publisher
spec:
  kind: PostDaprPubSub
  queries:
    product-updates: >
      {
        "pubsubName": "drasi-pubsub",
        "topicName": "product-changes",
        "format": "Packed",
        "skipControlSignals": false
      }
```

**Output Formats:**
1. **Packed**: Complete ChangeEvent as CloudEvent data
2. **Unpacked** (default): Individual changes as separate messages

**Unpacked Message Example:**
```json
{
    "op": "u",  // operation type
    "ts_ms": 1678886400350,
    "payload": {
        "source": {
            "queryId": "inventory-alerts",
            "ts_ms": 1678886400300
        },
        "before": {"itemId": "SKU789", "stockLevel": 5},
        "after": {"itemId": "SKU789", "stockLevel": 3}
    }
}
```

## Architecture Benefits

1. **Declarative Change Detection**: Express complex change rules in a single Cypher query
2. **Multi-Source Queries**: Join data across different databases seamlessly
3. **Real-time Processing**: Changes are detected and distributed as they occur
4. **Flexible Integration**: Multiple reaction types for different consumption patterns
5. **Time-Aware**: Built-in temporal functions for time-based business logic

## Common Patterns

### Dashboard Integration
- Use SignalR reaction for real-time UI updates
- ResultSet component handles all subscription and update logic
- Combine with traditional APIs for user actions

### Microservice Data Synchronization
- Use SyncDaprStateStore for read-optimized views
- Pre-compute complex aggregations in Continuous Queries
- Access via simple key-value lookups

### Event-Driven Workflows
- Use PostDaprPubSub to trigger business processes
- Filter and transform events at the query level
- Leverage Dapr's pub/sub resilience features

## Key Takeaways

1. Drasi transforms how we think about change detection - from simple CRUD notifications to sophisticated business event detection
2. The graph-based approach with Cypher makes complex queries intuitive
3. Three reaction types cover most integration scenarios: real-time UI (SignalR), synchronized state (SyncDaprStateStore), and event streaming (PostDaprPubSub)
4. Middleware capabilities allow data transformation before query processing
5. The platform abstracts away the complexity of monitoring diverse data sources while providing a unified change detection interface

## How Drasi Powers Dapr Applications

Drasi is particularly powerful for Dapr users because it complements Dapr's building blocks with sophisticated change detection and data distribution capabilities. Here are the key scenarios Drasi enables for Dapr applications:

### General Use Cases for Dapr Users

1. **Complex Event Processing**: Transform low-level database changes into high-level business events that Dapr applications can consume
2. **Cross-Service Data Aggregation**: Create unified views across multiple microservices' databases without tight coupling
3. **Real-time Monitoring & Alerting**: Detect complex conditions across distributed data and trigger Dapr workflows
4. **Data Synchronization**: Keep read models, caches, and materialized views in sync across services
5. **Legacy System Integration**: Bridge legacy databases to modern Dapr microservices with minimal code
6. **Time-Based Business Logic**: Implement SLA monitoring, expiration handling, and temporal rules
7. **Relationship-Aware Processing**: Leverage graph queries to detect changes in connected data
8. **Multi-Database Transactions**: Coordinate changes across different database types through event-driven patterns
9. **Audit & Compliance**: Track complex data lineage and changes for regulatory requirements
10. **Performance Optimization**: Offload complex queries from transactional systems to pre-computed views

### How Each Reaction Empowers Dapr Users

## 1. SignalR Reaction for Dapr Applications

The SignalR reaction bridges the gap between backend Dapr services and frontend applications with real-time capabilities.

### Benefits for Dapr Users:
- **Zero-Code Real-time UI**: Connect dashboards directly to query results without implementing WebSocket logic
- **Live Operations Dashboards**: Monitor microservice health, order status, inventory levels in real-time
- **Collaborative Features**: Build real-time collaborative apps where multiple users see synchronized data
- **Progressive Web Apps**: Enable offline-capable apps that sync when reconnected
- **Mobile Push Notifications**: Trigger mobile alerts based on complex backend conditions

### Example Scenarios:
1. **E-commerce Order Tracking**: 
   - Query monitors orders across order service, inventory service, and shipping service
   - Dashboard shows real-time order progress to customer service reps
   - No polling required - updates pushed instantly

2. **IoT Device Monitoring**:
   - Query aggregates device telemetry from multiple Dapr services
   - Operations dashboard shows device health, alerts, and metrics
   - Scales to thousands of devices with efficient change detection

3. **Financial Trading Dashboard**:
   - Query calculates portfolio positions across multiple services
   - Traders see real-time P&L, risk metrics, and positions
   - Sub-second latency from trade execution to UI update

## 2. PostDaprPubSub Reaction for Dapr Applications

The PostDaprPubSub reaction turns Drasi into a sophisticated event producer for Dapr's pub/sub building block.

### Benefits for Dapr Users:
- **Business Event Generation**: Convert technical database changes into meaningful business events
- **Event Enrichment**: Include related data in events through graph queries
- **Event Filtering**: Only publish events that meet complex criteria
- **Multi-Service Orchestration**: Trigger workflows across multiple Dapr services
- **Decoupled Architecture**: Services subscribe to business events, not database changes

### Example Scenarios:
1. **Order Fulfillment Workflow**:
   ```cypher
   MATCH (o:Order)-[:CONTAINS]->(i:Item),
         (i:Item)<-[:STOCKS]-(w:Warehouse)
   WHERE o.status = 'paid' AND w.quantity >= o.quantity
   RETURN o.orderId, w.warehouseId, i.itemId
   ```
   - Publishes "ReadyToShip" events when orders can be fulfilled
   - Warehouse service subscribes and creates pick lists
   - Shipping service subscribes and schedules deliveries

2. **Fraud Detection Pipeline**:
   ```cypher
   MATCH (c:Customer)-[:PLACED]->(o:Order)
   WHERE o.amount > c.avgOrderAmount * 3 
     AND o.shippingAddress <> c.defaultAddress
   RETURN c.customerId, o.orderId, o.amount
   ```
   - Publishes "SuspiciousOrder" events
   - Risk service subscribes for manual review
   - Notification service alerts security team

3. **Inventory Replenishment**:
   ```cypher
   MATCH (p:Product)-[:STOCKED_IN]->(w:Warehouse)
   WHERE w.quantity < p.reorderPoint 
     AND NOT EXISTS((p)-[:HAS_OPEN_ORDER]->(:PurchaseOrder))
   RETURN p.productId, w.warehouseId, p.reorderQuantity
   ```
   - Publishes "LowStock" events
   - Purchasing service creates purchase orders
   - Supplier integration service sends orders to vendors

## 3. SyncDaprStateStore Reaction for Dapr Applications

The SyncDaprStateStore reaction enables sophisticated read model patterns for Dapr applications.

### Benefits for Dapr Users:
- **Instant Read Models**: Query results automatically materialized in Dapr state
- **Microservice Autonomy**: Each service gets its own optimized data view
- **Performance at Scale**: Complex queries pre-computed, services just do key lookups
- **Consistency Guarantees**: Drasi ensures state store stays synchronized
- **Polyglot Support**: Any Dapr-enabled language can read the materialized data

### Example Scenarios:
1. **Customer 360 View**:
   ```cypher
   MATCH (c:Customer)-[:PLACED]->(o:Order),
         (c:Customer)-[:HAS]->(s:Subscription),
         (c:Customer)-[:OPENED]->(t:Ticket)
   RETURN c.customerId as customerId, 
          COUNT(DISTINCT o) as orderCount,
          SUM(o.total) as lifetimeValue,
          COLLECT(DISTINCT s.plan) as subscriptions,
          COUNT(t.status = 'open') as openTickets
   ```
   - Customer service reads complete customer context with single state lookup
   - No need to query multiple services in real-time
   - Updates automatically when any related data changes

2. **Product Catalog Aggregation**:
   ```cypher
   MATCH (p:Product)-[:IN_CATEGORY]->(c:Category),
         (p:Product)-[:HAS_INVENTORY]->(i:Inventory),
         (p:Product)<-[:REVIEWED]-(r:Review)
   RETURN p.productId as productId,
          p.name, p.price, c.name as category,
          SUM(i.quantity) as totalStock,
          AVG(r.rating) as avgRating,
          COUNT(r) as reviewCount
   ```
   - E-commerce frontend reads enriched product data
   - Combines data from product, inventory, and review services
   - Scales to millions of products with consistent performance

3. **Real-time Analytics Dashboard**:
   ```cypher
   MATCH (o:Order)-[:PLACED_BY]->(c:Customer)
   WHERE o.timestamp > datetime() - duration('PT1H')
   RETURN c.segment as customerSegment,
          COUNT(o) as orderCount,
          SUM(o.total) as revenue,
          AVG(o.total) as avgOrderValue
   ```
   - Analytics service reads pre-aggregated metrics
   - Updates every time a new order is placed
   - No need for batch ETL processes

### Architecture Patterns Enabled

1. **CQRS Implementation**: 
   - Write side: Dapr services handle commands
   - Read side: Drasi maintains query models in state stores
   - Complete separation of concerns

2. **Event Sourcing Support**:
   - Drasi reads from event stores
   - Materializes current state in Dapr state
   - Services work with current state, not event history

3. **Saga Orchestration**:
   - Drasi queries detect saga trigger conditions
   - PostDaprPubSub starts saga workflows
   - SyncDaprStateStore maintains saga state

4. **Cache Invalidation**:
   - Drasi detects what data changed
   - Reactions update only affected cache entries
   - No more cache stampedes or stale data

## Best Practices for Dapr + Drasi

1. **Start with Business Events**: Design queries around business concepts, not technical database changes
2. **Leverage Graph Relationships**: Use Cypher's power to traverse relationships across services
3. **Plan for Scale**: Use appropriate storage profiles for queries with large result sets
4. **Monitor Query Performance**: Use Drasi's metrics to optimize query execution
5. **Version Your Queries**: Treat Continuous Queries as code - version and test them
6. **Security First**: Use Dapr's security features with Drasi reactions
7. **Gradual Adoption**: Start with one use case, expand as you see value

## Conclusion

Drasi supercharges Dapr applications by providing a missing piece of the puzzle - sophisticated change detection and data distribution. While Dapr provides the building blocks for microservices (state, pub/sub, service invocation), Drasi provides the intelligence layer that knows what changed, why it matters, and who should know about it. Together, they enable a new class of reactive, real-time applications that would be extremely complex to build otherwise.

## Demo Environment: Drasi + Dapr E-commerce System

### Overview

This demo showcases a comprehensive e-commerce system built with Dapr microservices, enhanced by Drasi's change detection and distribution capabilities. The system demonstrates all three main Drasi reactions working together to create a reactive, real-time application.

### The Four Core Dapr Microservices

#### 1. **Products Service** (`/products-service`)
Manages product inventory and stock levels.

**Data Model:**
```json
{
  "productId": 1001,
  "productName": "Wireless Headphones",
  "productDescription": "High-quality Bluetooth headphones",
  "stockOnHand": 100,
  "lowStockThreshold": 20
}
```

**Key APIs:**
- `POST /products` - Create/update product
- `GET /products/{id}` - Get product details
- `PUT /products/{id}/increment` - Add stock (quantity)
- `PUT /products/{id}/decrement` - Remove stock (quantity)
- `DELETE /products/{id}` - Delete product

**Features:**
- Real-time stock tracking
- Low stock detection (isLowStock flag)
- Prevents negative inventory

#### 2. **Customers Service** (`/customers-service`)
Manages customer information and loyalty tiers.

**Data Model:**
```json
{
  "customerId": 2001,
  "customerName": "John Doe",
  "email": "john.doe@example.com",
  "loyaltyTier": "GOLD"  // BRONZE, SILVER, GOLD
}
```

**Key APIs:**
- `POST /customers` - Create customer (auto-generates ID if not provided)
- `GET /customers/{id}` - Get customer details
- `PUT /customers/{id}` - Update customer info
- `DELETE /customers/{id}` - Delete customer

**Features:**
- Three-tier loyalty system
- Email validation
- Auto-ID generation

#### 3. **Orders Service** (`/orders-service`)
Manages customer orders and order lifecycle.

**Data Model:**
```json
{
  "orderId": 3001,
  "customerId": 2001,
  "items": [
    {"productId": 1001, "quantity": 2},
    {"productId": 1002, "quantity": 1}
  ],
  "status": "PROCESSING"  // PENDING, PAID, PROCESSING, SHIPPED, DELIVERED, CANCELLED
}
```

**Key APIs:**
- `POST /orders` - Create order (initial status: PENDING)
- `GET /orders/{id}` - Get order details
- `PUT /orders/{id}/status` - Update order status
- `DELETE /orders/{id}` - Delete order

**Features:**
- Order lifecycle management
- Status transition validation
- Multi-item support

#### 4. **Reviews Service** (`/reviews-service`)
Manages product reviews and ratings.

**Data Model:**
```json
{
  "reviewId": 4001,
  "productId": 1001,
  "customerId": 2001,
  "rating": 5,  // 1-5
  "reviewText": "Excellent product!"
}
```

**Key APIs:**
- `POST /reviews` - Create review
- `GET /reviews/{id}` - Get review details
- `PUT /reviews/{id}` - Update rating/text
- `DELETE /reviews/{id}` - Delete review

**Features:**
- 1-5 star ratings
- Optional review text
- Product-customer association

### Additional Services for Drasi Demonstrations

#### 5. **Catalogue Service** (`/catalogue-service`) - Phase 3 Demo
A read-only service that demonstrates **SyncDaprStateStore** reaction.

**Purpose:** Shows how Drasi can maintain a pre-computed, enriched product catalog by combining data from products, orders, and reviews.

**Key APIs:**
- `GET /catalogue/{product_id}` - Get enriched product data
- `GET /catalogue` - List all catalog items

**Enriched Data Includes:**
- Product details
- Average rating from reviews
- Review count
- Order count
- Average quantity per order

#### 6. **Notifications Service** (`/notifications-service`) - Phase 4 Demo
Demonstrates **PostDaprPubSub** reaction for event-driven notifications.

**Purpose:** Shows how Drasi can detect business conditions and trigger appropriate notifications.

**Subscriptions:**
- `low-stock-events` - Products below threshold
- `critical-stock-events` - Products with zero stock

**Features:**
- Simulated email notifications
- Event statistics tracking
- Different urgency levels

#### 7. **Dashboard Service** (`/dashboard`) - Phase 2 Demo
A React-based real-time dashboard demonstrating **SignalR** reaction.

**Purpose:** Shows real-time UI updates without polling.

**Features:**
- Live order tracking
- Delayed Gold customer orders monitoring
- Real-time updates via SignalR
- Action buttons for order management

## The Four-Phase Drasi Demonstration

### Phase 1: Introduction to Drasi for Dapr Users

**What to Cover:**
1. Drasi as a change detection engine for Dapr applications
2. How it complements Dapr's building blocks
3. The three reactions and their use cases
4. Architecture overview of the demo system

**Key Points:**
- Drasi watches your Dapr state stores for changes
- Transforms low-level changes into business events
- Distributes changes through reactions
- No code changes needed in existing services

### Phase 2: SignalR Reaction - Real-time Dashboard

**Scenario:** Operations team needs to monitor orders and respond to issues in real-time.

**Demo Components:**
1. **Query: all-orders-with-product**
   - Tracks all orders containing a specific product (ID: 1010)
   - Shows order ID, product ID, and quantity

2. **Query: delayed-gold-orders**
   - Monitors GOLD tier customers with orders in PROCESSING status > 10 seconds
   - Uses Drasi's temporal function `drasi.trueFor()`
   - Returns customer details and wait time

**Demo Steps:**

1. **Setup:**
   ```bash
   # Start dashboard (already running)
   # Open browser to dashboard URL
   ```

2. **Create test data:**
   ```bash
   # Create a GOLD customer
   curl -X POST http://localhost/customers-service/customers \
     -H "Content-Type: application/json" \
     -d '{
       "customerId": 5001,
       "customerName": "VIP Customer",
       "email": "vip@example.com",
       "loyaltyTier": "GOLD"
     }'

   # Create product 1010 (tracked by dashboard)
   curl -X POST http://localhost/products-service/products \
     -H "Content-Type: application/json" \
     -d '{
       "productId": 1010,
       "productName": "Premium Laptop",
       "productDescription": "High-end laptop",
       "stockOnHand": 50,
       "lowStockThreshold": 10
     }'
   ```

3. **Demonstrate real-time updates:**
   ```bash
   # Create an order with product 1010
   curl -X POST http://localhost/orders-service/orders \
     -H "Content-Type: application/json" \
     -d '{
       "customerId": 5001,
       "items": [{"productId": 1010, "quantity": 1}]
     }'
   # Dashboard immediately shows the order

   # Update order to PROCESSING
   curl -X PUT http://localhost/orders-service/orders/{orderId}/status \
     -H "Content-Type: application/json" \
     -d '{"status": "PROCESSING"}'
   ```

4. **Show delayed order detection:**
   - Wait 10+ seconds with order in PROCESSING
   - Dashboard automatically shows it in delayed orders section
   - Demonstrate the "Backorder" and "Cancel" buttons

**Key Takeaways:**
- Zero polling - all updates pushed via SignalR
- Complex business logic (time-based delays) handled by Drasi
- Frontend stays simple with ResultSet component
- Multiple queries can feed one dashboard

### Phase 3: SyncDaprStateStore Reaction - Product Catalogue

**Scenario:** E-commerce site needs enriched product data combining information from multiple services.

**Demo Component:**
- **Query: product-catalogue**
  - Joins products, orders, and reviews
  - Calculates average rating, review count, order statistics
  - Materializes results in catalogue service's state store

**Demo Steps:**

1. **Initial state:**
   ```bash
   # Check empty catalogue
   curl http://localhost/catalogue-service/catalogue
   # Returns empty list
   ```

2. **Create product with reviews:**
   ```bash
   # Create a product
   curl -X POST http://localhost/products-service/products \
     -H "Content-Type: application/json" \
     -d '{
       "productId": 2001,
       "productName": "Smart Watch",
       "productDescription": "Fitness tracker with heart rate monitor",
       "stockOnHand": 100,
       "lowStockThreshold": 20
     }'

   # Add reviews
   curl -X POST http://localhost/reviews-service/reviews \
     -H "Content-Type: application/json" \
     -d '{
       "productId": 2001,
       "customerId": 1001,
       "rating": 5,
       "reviewText": "Amazing product!"
     }'

   curl -X POST http://localhost/reviews-service/reviews \
     -H "Content-Type: application/json" \
     -d '{
       "productId": 2001,
       "customerId": 1002,
       "rating": 4,
       "reviewText": "Good value"
     }'
   ```

3. **Create orders:**
   ```bash
   # Create orders for the product
   curl -X POST http://localhost/orders-service/orders \
     -H "Content-Type: application/json" \
     -d '{
       "customerId": 1001,
       "items": [{"productId": 2001, "quantity": 2}]
     }'
   ```

4. **Check enriched catalogue:**
   ```bash
   # Get catalogue entry
   curl http://localhost/catalogue-service/catalogue/2001
   
   # Returns enriched data:
   {
     "product_id": 2001,
     "product_name": "Smart Watch",
     "product_description": "Fitness tracker with heart rate monitor",
     "order_count": 1,
     "avg_quantity": 2.0,
     "avg_rating": 4.5,
     "review_count": 2
   }
   ```

5. **Show real-time updates:**
   ```bash
   # Add another review
   curl -X POST http://localhost/reviews-service/reviews \
     -H "Content-Type: application/json" \
     -d '{
       "productId": 2001,
       "customerId": 1003,
       "rating": 5,
       "reviewText": "Perfect!"
     }'

   # Check catalogue again - avg_rating updated to 4.67
   curl http://localhost/catalogue-service/catalogue/2001
   ```

**Key Takeaways:**
- Drasi maintains complex aggregations automatically
- Catalogue service has zero query logic - just key-value lookups
- Updates happen in real-time as source data changes
- Perfect for CQRS read models

### Phase 4: PostDaprPubSub Reaction - Stock Notifications

**Scenario:** Operations team needs alerts for stock issues to take immediate action.

**Demo Components:**
1. **Query: low-stock-event**
   - Detects products where stockOnHand <= lowStockThreshold
   - Triggers purchasing team notifications

2. **Query: critical-stock-event**  
   - Detects products with zero stock
   - Triggers urgent notifications to multiple teams

**Demo Steps:**

1. **Setup monitoring:**
   ```bash
   # Tail notifications service logs to see events
   kubectl logs -f deployment/notifications -n dapr-demos
   ```

2. **Create product near threshold:**
   ```bash
   # Create product with good stock
   curl -X POST http://localhost/products-service/products \
     -H "Content-Type: application/json" \
     -d '{
       "productId": 3001,
       "productName": "Bluetooth Speaker",
       "productDescription": "Portable wireless speaker",
       "stockOnHand": 25,
       "lowStockThreshold": 20
     }'
   ```

3. **Trigger low stock event:**
   ```bash
   # Decrement stock to trigger low stock
   curl -X PUT http://localhost/products-service/products/3001/decrement \
     -H "Content-Type: application/json" \
     -d '{"quantity": 10}'
   
   # Notifications service shows:
   # 📧 EMAIL TO: purchasing@company.com
   # Subject: Low Stock Alert - Bluetooth Speaker
   # Current Stock: 15 units
   # Low Stock Threshold: 20 units
   ```

4. **Trigger critical stock event:**
   ```bash
   # Decrement remaining stock
   curl -X PUT http://localhost/products-service/products/3001/decrement \
     -H "Content-Type: application/json" \
     -d '{"quantity": 15}'
   
   # Notifications service shows:
   # 🚨 CRITICAL ALERT - OUT OF STOCK
   # 📧 EMAIL TO: sales@company.com - Halt sales
   # 📧 EMAIL TO: fulfillment@company.com - Review pending orders
   # 🤖 AUTOMATED ACTIONS: Product marked out of stock
   ```

5. **Show event doesn't repeat:**
   ```bash
   # Try to decrement when already at zero
   curl -X PUT http://localhost/products-service/products/3001/decrement \
     -H "Content-Type: application/json" \
     -d '{"quantity": 1}'
   # Returns error, no new notifications

   # Increment stock
   curl -X PUT http://localhost/products-service/products/3001/increment \
     -H "Content-Type: application/json" \
     -d '{"quantity": 5}'
   # Low stock event fires again (stock=5, threshold=20)
   ```

**Key Takeaways:**
- Business events derived from data changes
- Different severity levels trigger different actions
- CloudEvents format for standards compliance
- Events only fire when conditions change

## Demo Summary Points

1. **No Service Modifications Required**
   - Original Dapr services unchanged
   - Drasi watches state stores via sources
   - New capabilities added declaratively

2. **Powerful Query Capabilities**
   - Graph queries across multiple services
   - Temporal functions for time-based logic
   - Aggregations and calculations
   - Rich filtering and transformations

3. **Three Complementary Reactions**
   - SignalR: Real-time UI without polling
   - SyncDaprStateStore: Pre-computed read models
   - PostDaprPubSub: Event-driven workflows

4. **Production Benefits**
   - Reduced latency (pre-computed views)
   - Lower service coupling
   - Simplified service logic
   - Consistent change detection

## Technical Architecture Notes

### Drasi Sources Configuration
Each Dapr service's state store is configured as a Drasi source with:
- Base64 decoding middleware
- JSON parsing middleware  
- Property promotion for easier querying

### Query Patterns
1. **Simple Filtering**: Low/critical stock queries
2. **Cross-Service Joins**: Product catalogue joining 3 services
3. **Temporal Logic**: Delayed orders using `drasi.trueFor()`
4. **Aggregations**: Average ratings, order counts

### Deployment Considerations
- All services use Dapr state management
- Drasi runs separately, monitoring state stores
- Reactions can scale independently
- State stores must support change feeds (PostgreSQL in demo)