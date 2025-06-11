#!/bin/bash

# Script to monitor notifications service for demo
echo "📧 Monitoring Notifications Service"
echo "==================================="
echo "Watching for stock alerts and other notifications..."
echo ""

kubectl logs -f deployment/notifications -n dapr-demos