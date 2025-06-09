import logging
import os
import json
import time
from contextlib import asynccontextmanager
from datetime import datetime
from typing import Any, Dict

from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from dapr.ext.fastapi import DaprApp
from dapr.clients import DaprClient

from models import (
    LowStockEvent, 
    CriticalStockEvent, 
    UnpackedDrasiEvent,
    NotificationStatus,
    NotificationResponse
)

# Configure logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Global notification status tracking
notification_status = NotificationStatus()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Notifications service started")
    logger.info("Subscribing to Dapr pub/sub topics:")
    logger.info("  - low-stock-events")
    logger.info("  - critical-stock-events")
    yield
    # Shutdown
    logger.info("Notifications service shutting down")


# Create FastAPI app
app = FastAPI(
    title="Notifications Service",
    description="Handles stock alerts from Drasi queries via Dapr pub/sub",
    version="1.0.0",
    lifespan=lifespan,
    root_path="/notifications-service"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create Dapr app
dapr_app = DaprApp(app)


def format_timestamp(ts_ms: int) -> str:
    """Convert millisecond timestamp to readable format."""
    return datetime.fromtimestamp(ts_ms / 1000).strftime("%Y-%m-%d %H:%M:%S")


def process_low_stock_event(event_data: Dict[str, Any]) -> LowStockEvent:
    """Process and validate low stock event data."""
    try:
        # Extract the Drasi event from CloudEvent wrapper
        drasi_data = event_data.get('data', event_data)
        
        # Handle unpacked Drasi event format
        unpacked_event = UnpackedDrasiEvent(**drasi_data)
        
        if unpacked_event.op == "i":  # Insert operation
            payload = unpacked_event.payload["after"]
        elif unpacked_event.op == "u":  # Update operation
            payload = unpacked_event.payload["after"]
        else:
            raise ValueError(f"Unexpected operation type: {unpacked_event.op}")
        
        return LowStockEvent(
            productId=payload["productId"],
            productName=payload["productName"],
            stockOnHand=payload["stockOnHand"],
            lowStockThreshold=payload["lowStockThreshold"],
            timestamp=format_timestamp(unpacked_event.ts_ms)
        )
    except Exception as e:
        logger.error(f"Error processing low stock event: {str(e)}")
        logger.error(f"Event data: {json.dumps(event_data, indent=2)}")
        raise


def process_critical_stock_event(event_data: Dict[str, Any]) -> CriticalStockEvent:
    """Process and validate critical stock event data."""
    try:
        # Extract the Drasi event from CloudEvent wrapper
        drasi_data = event_data.get('data', event_data)
        
        # Handle unpacked Drasi event format
        unpacked_event = UnpackedDrasiEvent(**drasi_data)
        
        if unpacked_event.op == "i":  # Insert operation
            payload = unpacked_event.payload["after"]
        elif unpacked_event.op == "u":  # Update operation
            payload = unpacked_event.payload["after"]
        else:
            raise ValueError(f"Unexpected operation type: {unpacked_event.op}")
        
        return CriticalStockEvent(
            productId=payload["productId"],
            productName=payload["productName"],
            productDescription=payload["productDescription"],
            timestamp=format_timestamp(unpacked_event.ts_ms)
        )
    except Exception as e:
        logger.error(f"Error processing critical stock event: {str(e)}")
        logger.error(f"Event data: {json.dumps(event_data, indent=2)}")
        raise


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "notifications"}


@app.get("/status", response_model=NotificationResponse)
async def get_notification_status():
    """Get current notification processing status."""
    return NotificationResponse(
        service="notifications",
        status="active",
        stats=notification_status.get_stats()
    )


@app.post("/reset-stats")
async def reset_stats():
    """Reset notification statistics."""
    notification_status.reset()
    logger.info("Notification statistics reset")
    return {"message": "Statistics reset successfully"}


@dapr_app.subscribe(pubsub="notifications-pubsub", topic="low-stock-events")
async def handle_low_stock_event(event_data: dict):
    """
    Handle low stock events from Drasi.
    Simulates sending email to purchasing team.
    """
    start_time = time.time()
    
    try:
        # Process the event
        event = process_low_stock_event(event_data)
        
        # Log the event details
        logger.warning(f"LOW STOCK ALERT - Product: {event.productName} (ID: {event.productId})")
        logger.warning(f"  Current Stock: {event.stockOnHand}")
        logger.warning(f"  Low Stock Threshold: {event.lowStockThreshold}")
        logger.warning(f"  Timestamp: {event.timestamp}")
        
        # Simulate email notification
        print("\n" + "="*70)
        print("📧 EMAIL NOTIFICATION TO: purchasing@company.com")
        print("="*70)
        print(f"Subject: Low Stock Alert - {event.productName}")
        print(f"\nDear Purchasing Team,")
        print(f"\nThis is an automated alert to notify you that the following product")
        print(f"has reached low stock levels and requires immediate attention:")
        print(f"\nProduct Details:")
        print(f"  - Product ID: {event.productId}")
        print(f"  - Product Name: {event.productName}")
        print(f"  - Current Stock: {event.stockOnHand} units")
        print(f"  - Low Stock Threshold: {event.lowStockThreshold} units")
        print(f"  - Alert Time: {event.timestamp}")
        print(f"\nRecommended Action:")
        print(f"  - Review current orders and forecast demand")
        print(f"  - Contact suppliers for restocking options")
        print(f"  - Place purchase order if necessary")
        print(f"\nBest regards,")
        print(f"Inventory Management System")
        print("="*70 + "\n")
        
        # Update statistics
        notification_status.low_stock_count += 1
        notification_status.last_low_stock_event = event.timestamp
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Low stock event processed successfully in {elapsed:.2f}ms")
        
        return {"status": "success"}
        
    except Exception as e:
        logger.error(f"Failed to process low stock event: {str(e)}")
        notification_status.error_count += 1
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process event: {str(e)}"
        )


@dapr_app.subscribe(pubsub="notifications-pubsub", topic="critical-stock-events")
async def handle_critical_stock_event(event_data: dict):
    """
    Handle critical stock events from Drasi.
    Simulates halting sales and notifying fulfillment team.
    """
    start_time = time.time()
    
    try:
        # Process the event
        event = process_critical_stock_event(event_data)
        
        # Log the critical event
        logger.critical(f"CRITICAL STOCK ALERT - Product: {event.productName} (ID: {event.productId})")
        logger.critical(f"  Product is OUT OF STOCK!")
        logger.critical(f"  Timestamp: {event.timestamp}")
        
        # Simulate critical notifications
        print("\n" + "="*70)
        print("🚨 CRITICAL ALERT - OUT OF STOCK 🚨")
        print("="*70)
        
        # Notification 1: Sales Team
        print("\n📧 EMAIL NOTIFICATION TO: sales@company.com")
        print(f"Subject: URGENT - Halt Sales for {event.productName}")
        print(f"\nDear Sales Team,")
        print(f"\nEFFECTIVE IMMEDIATELY: Please halt all sales for the following product")
        print(f"as it is now completely OUT OF STOCK:")
        print(f"\nProduct Details:")
        print(f"  - Product ID: {event.productId}")
        print(f"  - Product Name: {event.productName}")
        print(f"  - Description: {event.productDescription}")
        print(f"  - Stock Level: 0 units")
        print(f"  - Alert Time: {event.timestamp}")
        print(f"\nRequired Actions:")
        print(f"  1. Remove product from all active promotions")
        print(f"  2. Update product status to 'Out of Stock' on website")
        print(f"  3. Notify customers with pending orders")
        print(f"  4. Do not accept new orders for this product")
        
        # Notification 2: Fulfillment Team
        print("\n\n📧 EMAIL NOTIFICATION TO: fulfillment@company.com")
        print(f"Subject: URGENT - Stock Depletion Alert for {event.productName}")
        print(f"\nDear Fulfillment Team,")
        print(f"\nThis is a critical alert regarding stock depletion:")
        print(f"\nProduct Details:")
        print(f"  - Product ID: {event.productId}")
        print(f"  - Product Name: {event.productName}")
        print(f"  - Description: {event.productDescription}")
        print(f"  - Stock Level: 0 units")
        print(f"  - Alert Time: {event.timestamp}")
        print(f"\nRequired Actions:")
        print(f"  1. Review all pending orders containing this product")
        print(f"  2. Identify orders that cannot be fulfilled")
        print(f"  3. Prepare backorder notifications for affected customers")
        print(f"  4. Coordinate with purchasing for emergency restocking")
        
        # System Actions Simulation
        print("\n\n🤖 AUTOMATED SYSTEM ACTIONS:")
        print(f"  ✓ Product {event.productId} marked as 'Out of Stock' in catalog")
        print(f"  ✓ Sales channels notified to halt transactions")
        print(f"  ✓ Inventory system locked for this product")
        print(f"  ✓ Emergency restock request generated")
        print("="*70 + "\n")
        
        # Update statistics
        notification_status.critical_stock_count += 1
        notification_status.last_critical_event = event.timestamp
        
        elapsed = (time.time() - start_time) * 1000
        logger.info(f"Critical stock event processed successfully in {elapsed:.2f}ms")
        
        return {"status": "success"}
        
    except Exception as e:
        logger.error(f"Failed to process critical stock event: {str(e)}")
        notification_status.error_count += 1
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process event: {str(e)}"
        )


@app.get("/")
async def root():
    """Root endpoint with service information."""
    return {
        "service": "notifications",
        "version": "1.0.0",
        "description": "Handles stock alerts from Drasi queries via Dapr pub/sub",
        "endpoints": {
            "health": "/health",
            "status": "/status",
            "reset_stats": "/reset-stats"
        },
        "subscriptions": {
            "low-stock-events": "Handles products reaching low stock threshold",
            "critical-stock-events": "Handles products with zero stock"
        }
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)