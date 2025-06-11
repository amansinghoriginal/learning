#!/bin/bash

# Script to trigger critical (zero) stock alerts for demo
# Usage: ./trigger-critical-stock.sh [product_id]

PRODUCT_ID=${1:-3002}
BASE_URL="http://localhost"

echo "🚨 Critical Stock Alert Demo Script"
echo "===================================="

# Get current stock
response=$(curl -s "$BASE_URL/products-service/products/$PRODUCT_ID")
if [ $? -ne 0 ]; then
    echo "❌ Failed to get product $PRODUCT_ID"
    exit 1
fi

current_stock=$(echo "$response" | jq -r '.stockOnHand')
product_name=$(echo "$response" | jq -r '.productName')

echo "📦 Product: $product_name (ID: $PRODUCT_ID)"
echo "📊 Current Stock: $current_stock"
echo ""

if [ "$current_stock" -eq 0 ]; then
    echo "⚠️  Product is already out of stock!"
    echo "💡 Tip: Restock first with: ./restock-product.sh $PRODUCT_ID 30"
    exit 0
fi

echo "🔽 Decrementing ALL stock ($current_stock units) to trigger critical alert..."
echo ""
read -p "Press Enter to trigger CRITICAL stock alert..."

# Decrement all stock
curl -X PUT "$BASE_URL/products-service/products/$PRODUCT_ID/decrement" \
    -H "Content-Type: application/json" \
    -d "{\"quantity\": $current_stock}" | jq

echo ""
echo "🚨 CRITICAL stock alert should have been triggered!"
echo "📧 Check notifications logs for multiple alert emails"
echo ""
echo "Try decrementing again to show no duplicate alerts:"
echo "curl -X PUT $BASE_URL/products-service/products/$PRODUCT_ID/decrement -H \"Content-Type: application/json\" -d '{\"quantity\": 1}'"