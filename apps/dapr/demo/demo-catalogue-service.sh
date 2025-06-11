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

# Start of demo
clear
print_header "Create Product with Reviews for Drasi Catalogue Demo"
echo -e "${GREEN}This script will create a new product and reviews to demonstrate${NC}"
echo -e "${GREEN}Drasi's real-time synchronization to the catalogue service.${NC}"
echo

# Ask for product ID
echo -e "${YELLOW}Enter a product ID for the new product (e.g., 9999):${NC}"
read -p "> " PRODUCT_ID

# Validate input
if ! [[ "$PRODUCT_ID" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Invalid product ID. Using default: 9999${NC}"
    PRODUCT_ID=9999
fi

# Generate product details
PRODUCT_NAMES=("Ultra HD Smart TV" "Wireless Gaming Mouse" "Mechanical Keyboard Pro" "Noise Cancelling Headphones" "4K Action Camera" "Smart Home Hub" "Portable SSD Drive" "Gaming Monitor 144Hz" "Wireless Charging Pad" "Smart Fitness Tracker")
PRODUCT_DESCRIPTIONS=("Latest technology with stunning visuals" "High precision gaming mouse with RGB lighting" "Premium mechanical switches for typing enthusiasts" "Premium audio with active noise cancellation" "Capture your adventures in stunning 4K" "Control your entire smart home ecosystem" "Lightning fast storage for professionals" "Smooth gaming experience with low latency" "Fast wireless charging for all devices" "Track your health and fitness goals")

# Pick random product details
RANDOM_INDEX=$((RANDOM % ${#PRODUCT_NAMES[@]}))
PRODUCT_NAME="${PRODUCT_NAMES[$RANDOM_INDEX]}"
PRODUCT_DESC="${PRODUCT_DESCRIPTIONS[$RANDOM_INDEX]}"
STOCK=$((RANDOM % 100 + 50))  # Random stock between 50-150
THRESHOLD=$((RANDOM % 20 + 10))  # Random threshold between 10-30

# Create the product
echo
echo -e "${GREEN}Creating product ${PRODUCT_ID}: ${PRODUCT_NAME}${NC}"
echo

PRODUCT_JSON=$(cat <<EOF
{
  "productId": ${PRODUCT_ID},
  "productName": "${PRODUCT_NAME}",
  "productDescription": "${PRODUCT_DESC}",
  "stockOnHand": ${STOCK},
  "lowStockThreshold": ${THRESHOLD}
}
EOF
)

show_command "curl -X POST ${BASE_URL}/products-service/products \\
  -H \"Content-Type: application/json\" \\
  -d '${PRODUCT_JSON}'"

# Execute with retry
# Write JSON to temp file to avoid escaping issues
TEMP_FILE=$(mktemp)
echo "$PRODUCT_JSON" > "$TEMP_FILE"
output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/products-service/products -H 'Content-Type: application/json' -d @${TEMP_FILE}")
rm -f "$TEMP_FILE"
if [ $? -eq 0 ]; then
    echo "$output"
else
    echo -e "${RED}Failed to create product after multiple retries${NC}"
fi

echo
echo
echo -e "${YELLOW}Product created! Now let's add reviews...${NC}"
echo

# Ask for number of reviews
echo -e "${GREEN}How many reviews should we create for product ${PRODUCT_ID}?${NC}"
echo -e "${YELLOW}Enter a number between 1 and 20:${NC}"
read -p "> " NUM_REVIEWS

# Validate input
if ! [[ "$NUM_REVIEWS" =~ ^[0-9]+$ ]] || [ "$NUM_REVIEWS" -lt 1 ] || [ "$NUM_REVIEWS" -gt 20 ]; then
    echo -e "${RED}Invalid number. Using default: 5${NC}"
    NUM_REVIEWS=5
fi

echo
echo -e "${GREEN}Creating ${NUM_REVIEWS} reviews for product ${PRODUCT_ID}...${NC}"
echo

# Array of review texts
REVIEW_TEXTS=(
    "Excellent product! Highly recommended."
    "Good value for money. Works as expected."
    "Amazing quality! Will buy again."
    "Decent product with room for improvement."
    "Outstanding! Exceeded my expectations."
    "Solid choice. No complaints."
    "Fantastic! Best purchase this year."
    "Pretty good. Does what it says."
    "Superb quality and fast delivery."
    "Great product! Very satisfied."
    "Not bad. Gets the job done."
    "Impressive! Worth every penny."
    "Good product. Happy with purchase."
    "Excellent! Five stars."
    "Nice product. Would recommend."
    "Perfect! Exactly what I needed."
    "Very good. Met my expectations."
    "Top quality! Love it."
    "Good purchase. No regrets."
    "Wonderful! Highly satisfied."
)

# Create reviews
for i in $(seq 1 $NUM_REVIEWS); do
    # Generate random rating between 3 and 5 for positive demo
    RATING=$((RANDOM % 3 + 3))
    
    # Pick a random review text
    REVIEW_TEXT="${REVIEW_TEXTS[$((RANDOM % ${#REVIEW_TEXTS[@]}))]}"
    
    # Generate review ID
    REVIEW_ID=$((${PRODUCT_ID}000 + i))
    
    # Generate random customer ID between 1 and 10
    CUSTOMER_ID=$((RANDOM % 10 + 1))
    
    REVIEW_JSON=$(cat <<EOF
{
  "reviewId": ${REVIEW_ID},
  "productId": ${PRODUCT_ID},
  "customerId": ${CUSTOMER_ID},
  "rating": ${RATING},
  "reviewText": "${REVIEW_TEXT}"
}
EOF
)
    
    echo -e "${CYAN}Creating review ${i}/${NUM_REVIEWS} (Rating: ${RATING}⭐)...${NC}"
    
    show_command "curl -X POST ${BASE_URL}/reviews-service/reviews \\
  -H \"Content-Type: application/json\" \\
  -d '${REVIEW_JSON}'"
    
    # Execute with retry
    # Write JSON to temp file to avoid escaping issues
    TEMP_FILE=$(mktemp)
    echo "$REVIEW_JSON" > "$TEMP_FILE"
    output=$(execute_with_retry "curl -s -X POST ${BASE_URL}/reviews-service/reviews -H 'Content-Type: application/json' -d @${TEMP_FILE}")
    rm -f "$TEMP_FILE"
    if [ $? -eq 0 ]; then
        echo "$output"
    else
        echo -e "${RED}Failed to create review ${i} after multiple retries${NC}"
    fi
    
    echo
    echo
done

# Summary
print_header "Done!"

echo -e "${GREEN}${BOLD}Successfully created:${NC}"
echo -e "${BLUE}• Product ${PRODUCT_ID}: ${PRODUCT_NAME}${NC}"
echo -e "${BLUE}• ${NUM_REVIEWS} reviews with ratings between 3-5 stars${NC}"
echo
echo -e "${YELLOW}${BOLD}Next steps:${NC}"
echo -e "${YELLOW}Check if the product appears in the catalogue by running:${NC}"
echo
echo -e "${BOLD}curl ${BASE_URL}/catalogue-service/api/catalogue/${PRODUCT_ID} | jq .${NC}"
echo
echo -e "${GREEN}Drasi should have automatically synchronized this data to the catalogue!${NC}"
echo