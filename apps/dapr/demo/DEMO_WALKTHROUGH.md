# Drasi + Dapr E-commerce Demo Walkthrough

## Pre-Demo Setup

1. **Ensure all services are running**
   ```bash
   kubectl get pods -n dapr-demos
   # All pods should be in Running state
   ```

2. **Populate demo data**
   ```bash
   cd demo
   ./populate-demo-data.sh
   ```

3. **Open necessary terminals/tabs**
   - Terminal 1: For running demo commands
   - Terminal 2: For monitoring notifications service logs
   - Browser Tab 1: Dashboard (http://localhost/dashboard or your dashboard URL)
   - Browser Tab 2: Product Catalogue UI (if available)

---

## Phase 1: Introduction (5 minutes)

### Talking Points
- "Today we'll see how Drasi enhances Dapr applications with intelligent change detection"
- "We have 4 Dapr microservices: products, customers, orders, and reviews"
- "Drasi watches their state stores and reacts to changes through 3 reaction types"

### Show the Architecture
```bash
# Show running services
kubectl get pods -n dapr-demos

# Show Drasi components
kubectl get sources,continuousqueries,reactions -n drasi-system
```

---

## Phase 2: SignalR Reaction - Real-time Dashboard (10 minutes)

### Setup
1. **Open the dashboard in browser**
2. **Explain the two panels**: Orders with Product 1010, Delayed Gold Orders

### Demo Steps

#### Part A: Real-time Order Tracking

```bash
# 1. Show product 1010 exists
curl http://localhost/products-service/products/1010 | jq

# 2. Create a new order with product 1010
curl -X POST http://localhost/orders-service/orders \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": 7001,
    "customerId": 5201,
    "items": [{"productId": 1010, "quantity": 2}]
  }' | jq

# Watch dashboard - order appears immediately!

# 3. Update order status
curl -X PUT http://localhost/orders-service/orders/7001/status \
  -H "Content-Type: application/json" \
  -d '{"status": "PAID"}' | jq

# Dashboard updates in real-time
```

#### Part B: Delayed Gold Customer Orders

```bash
# 1. Show we have a GOLD customer
curl http://localhost/customers-service/customers/5001 | jq

# 2. Create order for GOLD customer
curl -X POST http://localhost/orders-service/orders \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": 7002,
    "customerId": 5001,
    "items": [{"productId": 1010, "quantity": 1}]
  }' | jq

# 3. Move to PAID status
curl -X PUT http://localhost/orders-service/orders/7002/status \
  -H "Content-Type: application/json" \
  -d '{"status": "PAID"}' | jq

# 4. Move to PROCESSING status
curl -X PUT http://localhost/orders-service/orders/7002/status \
  -H "Content-Type: application/json" \
  -d '{"status": "PROCESSING"}' | jq

# 5. WAIT 10+ seconds - order appears in delayed section!
# Explain: Drasi's temporal function detected the delay
```

### Key Points
- No polling - all updates pushed via SignalR
- Complex temporal logic (10-second delay) handled by Drasi
- Frontend stays simple with ResultSet component

---

## Phase 3: SyncDaprStateStore - Product Catalogue (10 minutes)

### Demo Steps

#### Part A: Show Empty Catalogue

```bash
# 1. Check catalogue is initially empty (or has existing data)
curl http://localhost/catalogue-service/catalogue | jq
```

#### Part B: Create Product with Reviews

```bash
# 1. Create a new product
curl -X POST http://localhost/products-service/products \
  -H "Content-Type: application/json" \
  -d '{
    "productId": 9001,
    "productName": "4K Webcam",
    "productDescription": "Professional streaming camera",
    "stockOnHand": 75,
    "lowStockThreshold": 15
  }' | jq

# 2. Check catalogue - product appears with no reviews
curl http://localhost/catalogue-service/catalogue/9001 | jq

# 3. Add first review
curl -X POST http://localhost/reviews-service/reviews \
  -H "Content-Type: application/json" \
  -d '{
    "reviewId": 9001,
    "productId": 9001,
    "customerId": 5101,
    "rating": 5,
    "reviewText": "Crystal clear video quality!"
  }' | jq

# 4. Check catalogue - avg_rating is now 5.0
curl http://localhost/catalogue-service/catalogue/9001 | jq

# 5. Add more reviews with different ratings
curl -X POST http://localhost/reviews-service/reviews \
  -H "Content-Type: application/json" \
  -d '{
    "reviewId": 9002,
    "productId": 9001,
    "customerId": 5102,
    "rating": 4,
    "reviewText": "Good but pricey"
  }' | jq

curl -X POST http://localhost/reviews-service/reviews \
  -H "Content-Type: application/json" \
  -d '{
    "reviewId": 9003,
    "productId": 9001,
    "customerId": 5103,
    "rating": 5,
    "reviewText": "Worth every penny"
  }' | jq

# 6. Check catalogue - avg_rating updated to 4.67
curl http://localhost/catalogue-service/catalogue/9001 | jq
```

#### Part C: Show Order Impact

```bash
# 1. Create orders for the product
curl -X POST http://localhost/orders-service/orders \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": 7003,
    "customerId": 5201,
    "items": [{"productId": 9001, "quantity": 3}]
  }' | jq

# 2. Check catalogue - order_count and avg_quantity updated
curl http://localhost/catalogue-service/catalogue/9001 | jq
```

### Key Points
- Drasi maintains complex aggregations automatically
- Catalogue service has zero query logic
- Updates happen in real-time as data changes
- Perfect for CQRS read models

---

## Phase 4: PostDaprPubSub - Stock Notifications (10 minutes)

### Setup
```bash
# Start monitoring notifications service
kubectl logs -f deployment/notifications -n dapr-demos
```

### Demo Steps

#### Part A: Low Stock Alert

```bash
# 1. Check product 3001 current state (created with 25 stock, 20 threshold)
curl http://localhost/products-service/products/3001 | jq

# 2. Decrement stock to trigger low stock (25 - 10 = 15, below 20 threshold)
curl -X PUT http://localhost/products-service/products/3001/decrement \
  -H "Content-Type: application/json" \
  -d '{"quantity": 10}' | jq

# Watch notifications log - LOW STOCK EMAIL sent!
```

#### Part B: Critical Stock Alert

```bash
# 1. Decrement to zero stock
curl -X PUT http://localhost/products-service/products/3001/decrement \
  -H "Content-Type: application/json" \
  -d '{"quantity": 15}' | jq

# Watch notifications log - CRITICAL ALERT with multiple emails!

# 2. Try to decrement again (should fail)
curl -X PUT http://localhost/products-service/products/3001/decrement \
  -H "Content-Type: application/json" \
  -d '{"quantity": 1}'

# No new notifications - Drasi only fires when state changes
```

#### Part C: Recovery Scenario

```bash
# 1. Restock the product
curl -X PUT http://localhost/products-service/products/3001/increment \
  -H "Content-Type: application/json" \
  -d '{"quantity": 30}' | jq

# No notifications - stock is above threshold

# 2. Decrement to low stock again
curl -X PUT http://localhost/products-service/products/3001/decrement \
  -H "Content-Type: application/json" \
  -d '{"quantity": 15}' | jq

# Low stock alert fires again!
```

### Key Points
- Business events derived from data changes
- Different severity levels trigger different actions
- Events only fire when conditions change
- Perfect for workflow triggers

---

## Advanced Scenarios (Optional)

### Cross-Service Query Power

```bash
# Show how a single order update affects multiple queries

# 1. Create a complex order
curl -X POST http://localhost/orders-service/orders \
  -H "Content-Type: application/json" \
  -d '{
    "orderId": 8001,
    "customerId": 5001,
    "items": [
      {"productId": 1010, "quantity": 1},
      {"productId": 3001, "quantity": 5}
    ]
  }' | jq

# This single order:
# - Appears in dashboard (has product 1010)
# - Updates catalogue statistics
# - Might trigger stock alerts
# - All from one state change!
```

### Time-based Logic Demo

```bash
# Create multiple GOLD customer orders and show batch delay detection

for i in {1..3}; do
  curl -X POST http://localhost/orders-service/orders \
    -H "Content-Type: application/json" \
    -d "{
      \"orderId\": $((8100 + i)),
      \"customerId\": $((5001 + i)),
      \"items\": [{\"productId\": 1010, \"quantity\": 1}]
    }" | jq
  
  curl -X PUT http://localhost/orders-service/orders/$((8100 + i))/status \
    -H "Content-Type: application/json" \
    -d '{"status": "PAID"}' | jq
  
  curl -X PUT http://localhost/orders-service/orders/$((8100 + i))/status \
    -H "Content-Type: application/json" \
    -d '{"status": "PROCESSING"}' | jq
done

# Wait 10 seconds - all appear in dashboard together!
```

---

## Demo Summary

### Architecture Benefits Demonstrated
1. **No polling** - Real-time updates via SignalR
2. **No complex queries in services** - Drasi handles aggregations
3. **Declarative change detection** - Cypher queries define business rules
4. **Event-driven workflows** - Stock alerts trigger actions
5. **Time-aware processing** - Delayed order detection

### Business Value
- **Reduced latency** - Pre-computed views
- **Simplified services** - Focus on business logic
- **Scalable architecture** - Each reaction scales independently
- **Consistent change detection** - No missed events

### Next Steps for Attendees
1. Try the demo in their environment
2. Identify their own use cases for change detection
3. Start with one reaction type
4. Expand as they see value

---

## Troubleshooting

### If dashboard doesn't update:
```bash
# Check SignalR reaction
kubectl logs deployment/signalr-reaction -n drasi-system

# Check continuous queries
kubectl get continuousqueries -n drasi-system
```

### If notifications don't appear:
```bash
# Check notifications service
kubectl logs deployment/notifications -n dapr-demos

# Check PostDaprPubSub reaction
kubectl logs deployment/post-dapr-pubsub-reaction -n drasi-system
```

### If catalogue doesn't sync:
```bash
# Check SyncDaprStateStore reaction
kubectl logs deployment/sync-dapr-statestore-reaction -n drasi-system

# Verify state store components exist in both namespaces
kubectl get components -n dapr-demos
kubectl get components -n drasi-system
```