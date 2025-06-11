#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Base URL - update if your services are not on localhost
BASE_URL="http://localhost"

echo -e "${BLUE}=== Drasi E-commerce Demo Data Population ===${NC}"
echo -e "${YELLOW}This script will populate realistic e-commerce data for demonstrating Drasi reactions${NC}\n"

# Keep track of created IDs for consistent references
declare -a CUSTOMER_IDS=()
declare -a PRODUCT_IDS=()
declare -a ORDER_IDS=()

# Function to make API calls with error handling
call_api() {
    local method=$1
    local endpoint=$2
    local data=$3
    local service=$4
    
    if [ "$method" == "POST" ] || [ "$method" == "PUT" ]; then
        response=$(curl -s -X $method "$BASE_URL/$service/$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data" -w "\n%{http_code}")
    else
        response=$(curl -s -X $method "$BASE_URL/$service/$endpoint" -w "\n%{http_code}")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo "$body"
        return 0
    else
        echo -e "${RED}Error calling $endpoint: HTTP $http_code${NC}" >&2
        echo "$body" >&2
        return 1
    fi
}

echo -e "${GREEN}1. Creating Customers (Different Loyalty Tiers)${NC}"
echo "Creating 20 customers with mixed loyalty tiers..."

# Gold customers (for delayed order demo)
for i in {1..5}; do
    customer_id=$((5000 + i))
    response=$(call_api POST "customers" "{
        \"customerId\": $customer_id,
        \"customerName\": \"Gold Customer $i\",
        \"email\": \"gold$i@example.com\",
        \"loyaltyTier\": \"GOLD\"
    }" "customers-service")
    if [ $? -eq 0 ]; then
        CUSTOMER_IDS+=($customer_id)
        echo "  ✓ Created GOLD customer: $customer_id"
    fi
done

# Silver customers
for i in {1..7}; do
    customer_id=$((5100 + i))
    response=$(call_api POST "customers" "{
        \"customerId\": $customer_id,
        \"customerName\": \"Silver Customer $i\",
        \"email\": \"silver$i@example.com\",
        \"loyaltyTier\": \"SILVER\"
    }" "customers-service")
    if [ $? -eq 0 ]; then
        CUSTOMER_IDS+=($customer_id)
        echo "  ✓ Created SILVER customer: $customer_id"
    fi
done

# Bronze customers
for i in {1..8}; do
    customer_id=$((5200 + i))
    response=$(call_api POST "customers" "{
        \"customerId\": $customer_id,
        \"customerName\": \"Bronze Customer $i\",
        \"email\": \"bronze$i@example.com\",
        \"loyaltyTier\": \"BRONZE\"
    }" "customers-service")
    if [ $? -eq 0 ]; then
        CUSTOMER_IDS+=($customer_id)
        echo "  ✓ Created BRONZE customer: $customer_id"
    fi
done

echo -e "\n${GREEN}2. Creating Products (Various Categories)${NC}"
echo "Creating 30 products with different stock levels..."

# Electronics category
electronics=("Laptop" "Smartphone" "Tablet" "Smartwatch" "Headphones" "Camera" "Monitor" "Keyboard" "Mouse" "Speaker")
for i in "${!electronics[@]}"; do
    product_id=$((1000 + i + 1))
    stock=$((RANDOM % 150 + 20))  # 20-170 stock
    low_threshold=$((stock / 5))   # 20% of stock
    
    response=$(call_api POST "products" "{
        \"productId\": $product_id,
        \"productName\": \"${electronics[$i]}\",
        \"productDescription\": \"High-quality ${electronics[$i]} with premium features\",
        \"stockOnHand\": $stock,
        \"lowStockThreshold\": $low_threshold
    }" "products-service")
    if [ $? -eq 0 ]; then
        PRODUCT_IDS+=($product_id)
        echo "  ✓ Created product: $product_id - ${electronics[$i]} (Stock: $stock)"
    fi
done

# Special product 1010 for dashboard demo (mentioned in CLAUDE.md)
response=$(call_api POST "products" "{
    \"productId\": 1010,
    \"productName\": \"Premium Laptop Pro\",
    \"productDescription\": \"Top-tier laptop for professionals\",
    \"stockOnHand\": 50,
    \"lowStockThreshold\": 10
}" "products-service")
if [ $? -eq 0 ]; then
    PRODUCT_IDS+=(1010)
    echo "  ✓ Created special product: 1010 - Premium Laptop Pro (for dashboard demo)"
fi

# Fashion category
fashion=("T-Shirt" "Jeans" "Sneakers" "Jacket" "Hat" "Scarf" "Belt" "Sunglasses" "Watch" "Backpack")
for i in "${!fashion[@]}"; do
    product_id=$((2000 + i + 1))
    stock=$((RANDOM % 100 + 10))  # 10-110 stock
    low_threshold=$((stock / 4))   # 25% of stock
    
    response=$(call_api POST "products" "{
        \"productId\": $product_id,
        \"productName\": \"${fashion[$i]}\",
        \"productDescription\": \"Stylish ${fashion[$i]} for everyday wear\",
        \"stockOnHand\": $stock,
        \"lowStockThreshold\": $low_threshold
    }" "products-service")
    if [ $? -eq 0 ]; then
        PRODUCT_IDS+=($product_id)
        echo "  ✓ Created product: $product_id - ${fashion[$i]} (Stock: $stock)"
    fi
done

# Products with low stock for notification demo
echo -e "\n${YELLOW}Creating products near/at low stock threshold for notification demos:${NC}"

response=$(call_api POST "products" "{
    \"productId\": 3001,
    \"productName\": \"Wireless Earbuds\",
    \"productDescription\": \"Premium sound quality earbuds\",
    \"stockOnHand\": 25,
    \"lowStockThreshold\": 20
}" "products-service")
if [ $? -eq 0 ]; then
    PRODUCT_IDS+=(3001)
    echo "  ✓ Created low-stock product: 3001 - Wireless Earbuds (25/20 threshold)"
fi

response=$(call_api POST "products" "{
    \"productId\": 3002,
    \"productName\": \"USB-C Hub\",
    \"productDescription\": \"Multi-port connectivity hub\",
    \"stockOnHand\": 5,
    \"lowStockThreshold\": 10
}" "products-service")
if [ $? -eq 0 ]; then
    PRODUCT_IDS+=(3002)
    echo "  ✓ Created critical-stock product: 3002 - USB-C Hub (5/10 threshold)"
fi

echo -e "\n${GREEN}3. Creating Reviews${NC}"
echo "Creating reviews for products to demonstrate catalog enrichment..."

# Create reviews for various products
rating_comments=(
    "5:Excellent product! Exceeded my expectations."
    "4:Very good quality, minor issues but overall satisfied."
    "5:Amazing! Would definitely recommend."
    "3:Average product, does the job but nothing special."
    "4:Good value for money, happy with purchase."
    "5:Outstanding quality and fast delivery!"
    "2:Not as described, disappointed."
    "4:Solid product, works as expected."
    "5:Best purchase I've made this year!"
    "3:Okay product, could be better."
)

review_id=4000
for product_id in "${PRODUCT_IDS[@]:0:15}"; do  # Review first 15 products
    num_reviews=$((RANDOM % 5 + 1))  # 1-5 reviews per product
    
    for ((r=1; r<=num_reviews; r++)); do
        review_id=$((review_id + 1))
        customer_idx=$((RANDOM % ${#CUSTOMER_IDS[@]}))
        customer_id=${CUSTOMER_IDS[$customer_idx]}
        
        rating_idx=$((RANDOM % ${#rating_comments[@]}))
        IFS=':' read -r rating comment <<< "${rating_comments[$rating_idx]}"
        
        response=$(call_api POST "reviews" "{
            \"reviewId\": $review_id,
            \"productId\": $product_id,
            \"customerId\": $customer_id,
            \"rating\": $rating,
            \"reviewText\": \"$comment\"
        }" "reviews-service")
        if [ $? -eq 0 ]; then
            echo "  ✓ Created review $review_id for product $product_id (★ $rating)"
        fi
    done
done

echo -e "\n${GREEN}4. Creating Orders${NC}"
echo "Creating various orders in different states..."

order_id=6000

# Create some delivered orders (historical data)
echo -e "${BLUE}Creating historical (delivered) orders:${NC}"
for i in {1..10}; do
    order_id=$((order_id + 1))
    customer_idx=$((RANDOM % ${#CUSTOMER_IDS[@]}))
    customer_id=${CUSTOMER_IDS[$customer_idx]}
    
    # Random 1-3 items per order
    num_items=$((RANDOM % 3 + 1))
    items="["
    for ((j=1; j<=num_items; j++)); do
        product_idx=$((RANDOM % ${#PRODUCT_IDS[@]}))
        product_id=${PRODUCT_IDS[$product_idx]}
        quantity=$((RANDOM % 3 + 1))
        
        items+="{\"productId\": $product_id, \"quantity\": $quantity}"
        if [ $j -lt $num_items ]; then
            items+=","
        fi
    done
    items+="]"
    
    # Create order
    response=$(call_api POST "orders" "{
        \"orderId\": $order_id,
        \"customerId\": $customer_id,
        \"items\": $items
    }" "orders-service")
    
    if [ $? -eq 0 ]; then
        ORDER_IDS+=($order_id)
        # Move through order lifecycle
        call_api PUT "orders/$order_id/status" '{"status": "PAID"}' "orders-service" > /dev/null
        call_api PUT "orders/$order_id/status" '{"status": "PROCESSING"}' "orders-service" > /dev/null
        call_api PUT "orders/$order_id/status" '{"status": "SHIPPED"}' "orders-service" > /dev/null
        call_api PUT "orders/$order_id/status" '{"status": "DELIVERED"}' "orders-service" > /dev/null
        echo "  ✓ Created delivered order: $order_id (Customer: $customer_id)"
    fi
done

# Create some orders in various active states
echo -e "\n${BLUE}Creating active orders in different states:${NC}"

# PAID orders
for i in {1..5}; do
    order_id=$((order_id + 1))
    customer_idx=$((RANDOM % ${#CUSTOMER_IDS[@]}))
    customer_id=${CUSTOMER_IDS[$customer_idx]}
    
    response=$(call_api POST "orders" "{
        \"orderId\": $order_id,
        \"customerId\": $customer_id,
        \"items\": [{\"productId\": ${PRODUCT_IDS[0]}, \"quantity\": 1}]
    }" "orders-service")
    
    if [ $? -eq 0 ]; then
        ORDER_IDS+=($order_id)
        call_api PUT "orders/$order_id/status" '{"status": "PAID"}' "orders-service" > /dev/null
        echo "  ✓ Created PAID order: $order_id"
    fi
done

# PROCESSING orders (not from GOLD customers)
echo -e "\n${BLUE}Creating PROCESSING orders from non-GOLD customers:${NC}"
for i in {1..3}; do
    order_id=$((order_id + 1))
    # Pick a silver or bronze customer
    customer_id=${CUSTOMER_IDS[$((10 + i))]}  # Skip gold customers (indices 0-4)
    
    response=$(call_api POST "orders" "{
        \"orderId\": $order_id,
        \"customerId\": $customer_id,
        \"items\": [{\"productId\": ${PRODUCT_IDS[1]}, \"quantity\": 2}]
    }" "orders-service")
    
    if [ $? -eq 0 ]; then
        ORDER_IDS+=($order_id)
        call_api PUT "orders/$order_id/status" '{"status": "PAID"}' "orders-service" > /dev/null
        call_api PUT "orders/$order_id/status" '{"status": "PROCESSING"}' "orders-service" > /dev/null
        echo "  ✓ Created PROCESSING order: $order_id"
    fi
done

# Orders with product 1010 for dashboard demo
echo -e "\n${YELLOW}Creating orders with product 1010 for dashboard demo:${NC}"
for i in {1..3}; do
    order_id=$((order_id + 1))
    customer_idx=$((RANDOM % ${#CUSTOMER_IDS[@]}))
    customer_id=${CUSTOMER_IDS[$customer_idx]}
    
    response=$(call_api POST "orders" "{
        \"orderId\": $order_id,
        \"customerId\": $customer_id,
        \"items\": [{\"productId\": 1010, \"quantity\": 1}, {\"productId\": ${PRODUCT_IDS[2]}, \"quantity\": 1}]
    }" "orders-service")
    
    if [ $? -eq 0 ]; then
        ORDER_IDS+=($order_id)
        echo "  ✓ Created order with product 1010: $order_id"
    fi
done

# Create pending orders from GOLD customers for demo
echo -e "\n${YELLOW}Creating PENDING orders from GOLD customers for delayed order demo:${NC}"
for i in {1..3}; do
    order_id=$((order_id + 1))
    gold_customer_id=${CUSTOMER_IDS[$((i-1))]}  # First 3 gold customers
    
    response=$(call_api POST "orders" "{
        \"orderId\": $order_id,
        \"customerId\": $gold_customer_id,
        \"items\": [{\"productId\": 1010, \"quantity\": 1}]
    }" "orders-service")
    
    if [ $? -eq 0 ]; then
        ORDER_IDS+=($order_id)
        echo "  ✓ Created PENDING order for GOLD customer: $order_id (Customer: $gold_customer_id)"
        echo "    Use this order ID during demo: $order_id"
    fi
done

echo -e "\n${GREEN}=== Data Population Complete! ===${NC}"
echo -e "\n${BLUE}Summary:${NC}"
echo "  - Customers created: ${#CUSTOMER_IDS[@]} (5 GOLD, 7 SILVER, 8 BRONZE)"
echo "  - Products created: ${#PRODUCT_IDS[@]} (including special products for demos)"
echo "  - Reviews created: Multiple per product"
echo "  - Orders created: ${#ORDER_IDS[@]} in various states"

echo -e "\n${YELLOW}Key IDs for demos:${NC}"
echo "  - Product 1010: Premium Laptop Pro (tracked by dashboard)"
echo "  - Product 3001: Wireless Earbuds (low stock: 25/20)"
echo "  - Product 3002: USB-C Hub (critical stock: 5/10)"
echo "  - Gold Customer IDs: 5001-5005"
echo "  - Recent PENDING orders from GOLD customers: ${ORDER_IDS[@]: -3}"

echo -e "\n${GREEN}Ready for Drasi demos!${NC}"