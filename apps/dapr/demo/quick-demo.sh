#!/bin/bash

# Quick demo script that runs through all reactions
# Perfect for a 5-minute lightning demo

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_URL="http://localhost"

echo -e "${BLUE}=== Drasi + Dapr Quick Demo ===${NC}"
echo "This script demonstrates all three Drasi reactions in action"
echo ""

read -p "Press Enter to start the demo..."

echo -e "\n${GREEN}1. SignalR Demo - Real-time Dashboard${NC}"
echo "Creating an order with product 1010 (watched by dashboard)..."

ORDER_ID=$((RANDOM + 20000))
curl -X POST "$BASE_URL/orders-service/orders" \
    -H "Content-Type: application/json" \
    -d "{
        \"orderId\": $ORDER_ID,
        \"customerId\": 5101,
        \"items\": [{\"productId\": 1010, \"quantity\": 2}]
    }" | jq

echo -e "${YELLOW}✓ Check dashboard - order should appear immediately!${NC}"
read -p "Press Enter to continue..."

echo -e "\n${GREEN}2. SyncDaprStateStore Demo - Product Catalogue${NC}"
echo "Creating a product with reviews to show enriched catalogue..."

PRODUCT_ID=$((RANDOM + 10000))
curl -X POST "$BASE_URL/products-service/products" \
    -H "Content-Type: application/json" \
    -d "{
        \"productId\": $PRODUCT_ID,
        \"productName\": \"Demo Product\",
        \"productDescription\": \"Live demo product\",
        \"stockOnHand\": 100,
        \"lowStockThreshold\": 20
    }" | jq

echo "Adding reviews..."
for rating in 5 4 5; do
    curl -X POST "$BASE_URL/reviews-service/reviews" \
        -H "Content-Type: application/json" \
        -d "{
            \"productId\": $PRODUCT_ID,
            \"customerId\": 5101,
            \"rating\": $rating,
            \"reviewText\": \"Demo review\"
        }" > /dev/null 2>&1
done

echo "Checking enriched catalogue..."
sleep 2
curl "$BASE_URL/catalogue-service/catalogue/$PRODUCT_ID" | jq

echo -e "${YELLOW}✓ Catalogue shows aggregated data: avg rating, review count!${NC}"
read -p "Press Enter to continue..."

echo -e "\n${GREEN}3. PostDaprPubSub Demo - Stock Alerts${NC}"
echo "Creating a product and triggering low stock alert..."

ALERT_PRODUCT=$((RANDOM + 30000))
curl -X POST "$BASE_URL/products-service/products" \
    -H "Content-Type: application/json" \
    -d "{
        \"productId\": $ALERT_PRODUCT,
        \"productName\": \"Alert Demo Product\",
        \"productDescription\": \"Product for alert demo\",
        \"stockOnHand\": 25,
        \"lowStockThreshold\": 20
    }" | jq

echo "Triggering low stock by decrementing to 15 units..."
curl -X PUT "$BASE_URL/products-service/products/$ALERT_PRODUCT/decrement" \
    -H "Content-Type: application/json" \
    -d '{"quantity": 10}' | jq

echo -e "${YELLOW}✓ Check notifications service logs for low stock alert!${NC}"
echo ""

echo -e "${GREEN}=== Demo Complete! ===${NC}"
echo -e "\n${BLUE}Key Takeaways:${NC}"
echo "1. SignalR: Real-time UI updates without polling"
echo "2. SyncDaprStateStore: Pre-computed views with zero query logic"
echo "3. PostDaprPubSub: Business events from data changes"
echo ""
echo "All achieved without modifying the original Dapr services!"