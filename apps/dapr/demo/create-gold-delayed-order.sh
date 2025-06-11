#!/bin/bash

# Script to create and process a GOLD customer order for delayed order demo
# Usage: ./create-gold-delayed-order.sh [customer_id]

CUSTOMER_ID=${1:-5001}
BASE_URL="http://localhost"

echo "⏱️  Delayed GOLD Order Demo Script"
echo "=================================="

# Verify customer is GOLD
response=$(curl -s "$BASE_URL/customers-service/customers/$CUSTOMER_ID")
if [ $? -ne 0 ]; then
    echo "❌ Failed to get customer $CUSTOMER_ID"
    exit 1
fi

loyalty_tier=$(echo "$response" | jq -r '.loyaltyTier')
customer_name=$(echo "$response" | jq -r '.customerName')

if [ "$loyalty_tier" != "GOLD" ]; then
    echo "❌ Customer $CUSTOMER_ID is $loyalty_tier tier, not GOLD!"
    echo "💡 Use one of these GOLD customers: 5001, 5002, 5003, 5004, 5005"
    exit 1
fi

echo "👤 Customer: $customer_name (ID: $CUSTOMER_ID)"
echo "⭐ Loyalty Tier: GOLD"
echo ""

# Generate order ID
ORDER_ID=$((RANDOM + 10000))

echo "📝 Creating order $ORDER_ID with product 1010 (tracked by dashboard)..."

# Create order
curl -X POST "$BASE_URL/orders-service/orders" \
    -H "Content-Type: application/json" \
    -d "{
        \"orderId\": $ORDER_ID,
        \"customerId\": $CUSTOMER_ID,
        \"items\": [{\"productId\": 1010, \"quantity\": 1}]
    }" | jq

echo ""
echo "💳 Moving order to PAID status..."
curl -X PUT "$BASE_URL/orders-service/orders/$ORDER_ID/status" \
    -H "Content-Type: application/json" \
    -d '{"status": "PAID"}' | jq

echo ""
echo "⚙️  Moving order to PROCESSING status..."
curl -X PUT "$BASE_URL/orders-service/orders/$ORDER_ID/status" \
    -H "Content-Type: application/json" \
    -d '{"status": "PROCESSING"}' | jq

echo ""
echo "✅ Order $ORDER_ID is now in PROCESSING status"
echo ""
echo "⏰ WAIT 10+ SECONDS for the order to appear in the delayed orders section!"
echo "🖥️  Watch the dashboard to see it appear automatically"
echo ""
echo "📌 Order ID: $ORDER_ID"
echo "💡 You can ship or cancel this order from the dashboard"