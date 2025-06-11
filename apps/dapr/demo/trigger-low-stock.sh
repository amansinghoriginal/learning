#!/bin/bash

# Script to trigger low stock alerts for demo
# Usage: ./trigger-low-stock.sh [product_id]

PRODUCT_ID=${1:-3001}
BASE_URL="http://localhost"

echo "🔔 Low Stock Alert Demo Script"
echo "==============================="

# Get current stock
response=$(curl -s "$BASE_URL/products-service/products/$PRODUCT_ID")
if [ $? -ne 0 ]; then
    echo "❌ Failed to get product $PRODUCT_ID"
    exit 1
fi

current_stock=$(echo "$response" | jq -r '.stockOnHand')
low_threshold=$(echo "$response" | jq -r '.lowStockThreshold')
product_name=$(echo "$response" | jq -r '.productName')

echo "📦 Product: $product_name (ID: $PRODUCT_ID)"
echo "📊 Current Stock: $current_stock"
echo "⚠️  Low Stock Threshold: $low_threshold"
echo ""

if [ "$current_stock" -le "$low_threshold" ]; then
    echo "⚠️  Product is already at or below low stock threshold!"
    echo "💡 Tip: Restock first with: ./restock-product.sh $PRODUCT_ID 50"
    exit 0
fi

# Calculate how much to decrement
decrement_amount=$((current_stock - low_threshold + 5))
new_stock=$((current_stock - decrement_amount))

echo "🔽 Decrementing stock by $decrement_amount units..."
echo "📉 New stock will be: $new_stock (below threshold of $low_threshold)"
echo ""
read -p "Press Enter to trigger low stock alert..."

# Decrement stock
curl -X PUT "$BASE_URL/products-service/products/$PRODUCT_ID/decrement" \
    -H "Content-Type: application/json" \
    -d "{\"quantity\": $decrement_amount}" | jq

echo ""
echo "✅ Low stock alert should have been triggered!"
echo "📧 Check the notifications service logs for the alert email"