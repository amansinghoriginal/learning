#!/bin/bash

# Script to restock products
# Usage: ./restock-product.sh <product_id> <quantity>

PRODUCT_ID=${1:-3001}
QUANTITY=${2:-50}
BASE_URL="http://localhost"

echo "📦 Product Restock Script"
echo "========================"

# Get current stock
response=$(curl -s "$BASE_URL/products-service/products/$PRODUCT_ID")
if [ $? -ne 0 ]; then
    echo "❌ Failed to get product $PRODUCT_ID"
    exit 1
fi

current_stock=$(echo "$response" | jq -r '.stockOnHand')
product_name=$(echo "$response" | jq -r '.productName')
low_threshold=$(echo "$response" | jq -r '.lowStockThreshold')

echo "📦 Product: $product_name (ID: $PRODUCT_ID)"
echo "📊 Current Stock: $current_stock"
echo "⚠️  Low Stock Threshold: $low_threshold"
echo "➕ Adding: $QUANTITY units"
echo "📈 New Stock: $((current_stock + QUANTITY))"
echo ""

# Increment stock
curl -X PUT "$BASE_URL/products-service/products/$PRODUCT_ID/increment" \
    -H "Content-Type: application/json" \
    -d "{\"quantity\": $QUANTITY}" | jq

echo ""
echo "✅ Product restocked successfully!"