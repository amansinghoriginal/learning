# Drasi + Dapr Demo Scripts

This folder contains scripts and guides for demonstrating Drasi's capabilities with Dapr microservices.

## Contents

### 1. Data Population
- **`populate-demo-data.sh`** - Creates realistic e-commerce data across all services
  - 20 customers (5 GOLD, 7 SILVER, 8 BRONZE)
  - 30+ products with varying stock levels
  - Multiple reviews per product
  - Orders in various states

### 2. Demo Walkthrough
- **`DEMO_WALKTHROUGH.md`** - Comprehensive guide for presenting all Drasi reactions
  - Phase-by-phase instructions
  - Exact commands to run
  - Expected outcomes
  - Troubleshooting tips

### 3. Helper Scripts

#### Stock Alert Demos
- **`trigger-low-stock.sh [product_id]`** - Triggers low stock notification
- **`trigger-critical-stock.sh [product_id]`** - Triggers zero stock critical alert
- **`restock-product.sh <product_id> <quantity>`** - Restocks a product

#### Dashboard Demos
- **`create-gold-delayed-order.sh [customer_id]`** - Creates order that will appear as delayed

#### Monitoring
- **`monitor-notifications.sh`** - Tails notifications service logs

#### Quick Demo
- **`quick-demo.sh`** - 5-minute demo hitting all three reactions

## Quick Start

1. **Populate demo data:**
   ```bash
   ./populate-demo-data.sh
   ```

2. **For a full demo:** Follow `DEMO_WALKTHROUGH.md`

3. **For a quick demo:**
   ```bash
   ./quick-demo.sh
   ```

## Key Demo Scenarios

### SignalR (Real-time Dashboard)
- Orders containing product 1010 appear instantly
- GOLD customer orders in PROCESSING > 10 seconds show as delayed

### SyncDaprStateStore (Product Catalogue)
- Products enriched with average ratings and order statistics
- Updates automatically as reviews/orders are added

### PostDaprPubSub (Stock Notifications)
- Low stock alerts when inventory drops below threshold
- Critical alerts when stock reaches zero
- No duplicate alerts for same condition

## Important IDs for Demos

- **Product 1010**: Premium Laptop Pro (tracked by dashboard)
- **Products 3001-3002**: Pre-configured for stock alerts
- **Customers 5001-5005**: GOLD tier customers
- **Customers 5101-5107**: SILVER tier customers
- **Customers 5201-5208**: BRONZE tier customers

## Tips for Presenters

1. Have multiple terminal windows open:
   - One for running commands
   - One for monitoring notifications
   - Dashboard in browser

2. Run `populate-demo-data.sh` before each demo session for clean data

3. Use the helper scripts to avoid typos during live demos

4. The `quick-demo.sh` is perfect for time-constrained presentations

5. Check the troubleshooting section in `DEMO_WALKTHROUGH.md` if something doesn't work as expected