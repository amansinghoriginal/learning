#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Base URL for services
BASE_URL="http://localhost"

# Helper function to print headers
print_header() {
    echo
    echo -e "${CYAN}${BOLD}===================================================${NC}"
    echo -e "${CYAN}${BOLD}$1${NC}"
    echo -e "${CYAN}${BOLD}===================================================${NC}"
    echo
}

# Helper function to show command
show_command() {
    echo -e "${GREEN}Running command:${NC}"
    echo -e "${BOLD}$1${NC}"
    echo
}

# Helper function to execute curl with retries
execute_with_retry() {
    local cmd="$1"
    local max_retries=3
    local retry_delay=2
    
    for i in $(seq 1 $max_retries); do
        # Execute command and capture output and exit code
        output=$(eval "$cmd" 2>&1)
        exit_code=$?
        
        # Check if successful or if output contains error patterns
        if [ $exit_code -eq 0 ] && ! echo "$output" | grep -q "_InactiveRpcError\|Socket closed\|StatusCode.UNAVAILABLE"; then
            echo "$output"
            return 0
        fi
        
        # If it's not the last retry, wait before retrying
        if [ $i -lt $max_retries ]; then
            sleep $retry_delay
        fi
    done
    
    # If all retries failed, return error
    return 1
}

# Helper function to ask Y/N questions
ask_yes_no() {
    local prompt="$1"
    local response
    echo -e "${YELLOW}${prompt} (Y/N):${NC}"
    read -p "> " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Start of demo
clear
print_header "Dashboard Service Demo - Stock Scenarios"
echo -e "${GREEN}This script demonstrates order and stock scenarios for the dashboard.${NC}"
echo -e "${GREEN}It will create a product and two orders with different stock implications.${NC}"
echo

# Ask if ready to proceed
if ! ask_yes_no "Ready to proceed with the demo?"; then
    echo -e "${RED}Demo cancelled.${NC}"
    exit 0
fi

# Generate random product ID and customer IDs
PRODUCT_ID=$((RANDOM % 9000 + 1000))  # Random ID between 1000-9999
CUSTOMER_ID_1=$((RANDOM % 100 + 5000))  # Random customer ID 5000-5099
CUSTOMER_ID_2=$((RANDOM % 100 + 5100))  # Random customer ID 5100-5199

echo
echo -e "${BLUE}Generated IDs:${NC}"
echo -e "${BLUE}• Product ID: ${PRODUCT_ID}${NC}"
echo -e "${BLUE}• Customer 1 ID: ${CUSTOMER_ID_1}${NC}"
echo -e "${BLUE}• Customer 2 ID: ${CUSTOMER_ID_2}${NC}"
echo

# Calculate quantities for the scenario
# First order will be for 40 units, product will have 30 units (75% of order)
# Second order will be for 20 units, product will then have 10 units (50% of second order)
ORDER_1_QTY=40
ORDER_2_QTY=20
INITIAL_STOCK=30  # 75% of first order
LOW_THRESHOLD=25  # Set threshold between final stock (10) and initial stock (30)

print_header "Step 1: Create Customers"

if ask_yes_no "Create two customers for the orders?"; then
    # Create first customer (GOLD tier for dashboard monitoring)
    echo
    echo -e "${GREEN}Creating Customer 1 (GOLD tier)...${NC}"
    
    CUSTOMER_1_JSON=$(cat <<EOF
{
  "customerId": ${CUSTOMER_ID_1},
  "customerName": "Demo Customer ${CUSTOMER_ID_1}",
  "email": "customer${CUSTOMER_ID_1}@demo.com",
  "loyaltyTier": "GOLD"
}
EOF
)
    
    show_command "curl -X POST ${BASE_URL}/customers-service/customers \\
  -H \"Content-Type: application/json\" \\
  -d '${CUSTOMER_1_JSON}'"
    
    TEMP_FILE=$(mktemp)
    echo "$CUSTOMER_1_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/customers-service/customers -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
    else
        echo -e "${RED}Failed to create customer 1${NC}"
    fi
    
    echo
    echo -e "${GREEN}Creating Customer 2 (SILVER tier)...${NC}"
    
    CUSTOMER_2_JSON=$(cat <<EOF
{
  "customerId": ${CUSTOMER_ID_2},
  "customerName": "Demo Customer ${CUSTOMER_ID_2}",
  "email": "customer${CUSTOMER_ID_2}@demo.com",
  "loyaltyTier": "SILVER"
}
EOF
)
    
    show_command "curl -X POST ${BASE_URL}/customers-service/customers \\
  -H \"Content-Type: application/json\" \\
  -d '${CUSTOMER_2_JSON}'"
    
    TEMP_FILE=$(mktemp)
    echo "$CUSTOMER_2_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/customers-service/customers -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
    else
        echo -e "${RED}Failed to create customer 2${NC}"
    fi
else
    echo -e "${YELLOW}Skipping customer creation...${NC}"
fi

echo
print_header "Step 2: Create Product with Specific Stock Level"

echo -e "${CYAN}Product will have:${NC}"
echo -e "${CYAN}• Initial stock: ${INITIAL_STOCK} units${NC}"
echo -e "${CYAN}• Low stock threshold: ${LOW_THRESHOLD} units${NC}"
echo

if ask_yes_no "Create the product with these specifications?"; then
    echo
    echo -e "${GREEN}Creating product ${PRODUCT_ID}...${NC}"
    
    PRODUCT_JSON=$(cat <<EOF
{
  "productId": ${PRODUCT_ID},
  "productName": "Dashboard Demo Product ${PRODUCT_ID}",
  "productDescription": "Product for demonstrating stock scenarios in dashboard",
  "stockOnHand": ${INITIAL_STOCK},
  "lowStockThreshold": ${LOW_THRESHOLD}
}
EOF
)
    
    show_command "curl -X POST ${BASE_URL}/products-service/products \\
  -H \"Content-Type: application/json\" \\
  -d '${PRODUCT_JSON}'"
    
    TEMP_FILE=$(mktemp)
    echo "$PRODUCT_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/products-service/products -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
    else
        echo -e "${RED}Failed to create product${NC}"
        exit 1
    fi
else
    echo -e "${RED}Cannot proceed without creating the product${NC}"
    exit 1
fi

echo
print_header "Step 3: Create First Order"

echo -e "${CYAN}First order details:${NC}"
echo -e "${CYAN}• Customer: ${CUSTOMER_ID_1} (GOLD)${NC}"
echo -e "${CYAN}• Product: ${PRODUCT_ID}${NC}"
echo -e "${CYAN}• Quantity: ${ORDER_1_QTY} units${NC}"
echo -e "${CYAN}• Available stock: ${INITIAL_STOCK} units (75% of order)${NC}"
echo
echo -e "${YELLOW}⚠️  This order will exceed available stock!${NC}"
echo

if ask_yes_no "Create the first order?"; then
    ORDER_1_ID=$((RANDOM % 9000 + 10000))  # Random order ID
    
    echo
    echo -e "${GREEN}Creating order ${ORDER_1_ID}...${NC}"
    
    ORDER_1_JSON=$(cat <<EOF
{
  "orderId": ${ORDER_1_ID},
  "customerId": ${CUSTOMER_ID_1},
  "items": [
    {
      "productId": ${PRODUCT_ID},
      "quantity": ${ORDER_1_QTY}
    }
  ],
  "status": "PENDING"
}
EOF
)
    
    show_command "curl -X POST ${BASE_URL}/orders-service/orders \\
  -H \"Content-Type: application/json\" \\
  -d '${ORDER_1_JSON}'"
    
    TEMP_FILE=$(mktemp)
    echo "$ORDER_1_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/orders-service/orders -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
        echo
        echo -e "${YELLOW}Order created. Note: Stock verification happens during order processing.${NC}"
    else
        echo -e "${RED}Failed to create order 1${NC}"
    fi
else
    echo -e "${YELLOW}Skipping first order...${NC}"
fi

echo
print_header "Step 4: Create Second Order"

echo -e "${CYAN}Second order details:${NC}"
echo -e "${CYAN}• Customer: ${CUSTOMER_ID_2} (SILVER)${NC}"
echo -e "${CYAN}• Product: ${PRODUCT_ID}${NC}"
echo -e "${CYAN}• Quantity: ${ORDER_2_QTY} units${NC}"
echo -e "${CYAN}• Stock after order 1: Will be at 50% of this order${NC}"
echo

if ask_yes_no "Create the second order?"; then
    ORDER_2_ID=$((RANDOM % 9000 + 20000))  # Random order ID
    
    echo
    echo -e "${GREEN}Creating order ${ORDER_2_ID}...${NC}"
    
    ORDER_2_JSON=$(cat <<EOF
{
  "orderId": ${ORDER_2_ID},
  "customerId": ${CUSTOMER_ID_2},
  "items": [
    {
      "productId": ${PRODUCT_ID},
      "quantity": ${ORDER_2_QTY}
    }
  ],
  "status": "PENDING"
}
EOF
)
    
    show_command "curl -X POST ${BASE_URL}/orders-service/orders \\
  -H \"Content-Type: application/json\" \\
  -d '${ORDER_2_JSON}'"
    
    TEMP_FILE=$(mktemp)
    echo "$ORDER_2_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/orders-service/orders -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "$output"
        echo
        echo -e "${YELLOW}Order created. Stock constraints will affect processing.${NC}"
    else
        echo -e "${RED}Failed to create order 2${NC}"
    fi
else
    echo -e "${YELLOW}Skipping second order...${NC}"
fi

echo
print_header "Demo Complete!"

echo -e "${GREEN}${BOLD}Summary of created entities:${NC}"
echo -e "${BLUE}• Product ${PRODUCT_ID}: Initial stock ${INITIAL_STOCK}, threshold ${LOW_THRESHOLD}${NC}"
echo -e "${BLUE}• Customer ${CUSTOMER_ID_1}: GOLD tier${NC}"
echo -e "${BLUE}• Customer ${CUSTOMER_ID_2}: SILVER tier${NC}"
if [ ! -z "$ORDER_1_ID" ]; then
    echo -e "${BLUE}• Order ${ORDER_1_ID}: ${ORDER_1_QTY} units (exceeds available stock)${NC}"
fi
if [ ! -z "$ORDER_2_ID" ]; then
    echo -e "${BLUE}• Order ${ORDER_2_ID}: ${ORDER_2_QTY} units${NC}"
fi

echo
echo -e "${YELLOW}${BOLD}Dashboard Monitoring:${NC}"
echo -e "${YELLOW}• Watch for orders appearing in the dashboard${NC}"
echo -e "${YELLOW}• Monitor stock level warnings${NC}"
echo -e "${YELLOW}• GOLD customer orders may show special handling${NC}"

echo
echo -e "${CYAN}${BOLD}Stock Scenario Results:${NC}"
echo -e "${CYAN}• Product started with ${INITIAL_STOCK} units (above threshold)${NC}"
echo -e "${CYAN}• First order requests ${ORDER_1_QTY} units (stock only 75% of order)${NC}"
echo -e "${CYAN}• Second order requests ${ORDER_2_QTY} units (stock would be 50% of order)${NC}"
echo