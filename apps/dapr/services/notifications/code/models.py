from pydantic import BaseModel, Field
from typing import Dict, Any, Optional, Union


class LowStockEvent(BaseModel):
    """Model for low stock event data."""
    productId: int = Field(..., description="Product identifier")
    productName: str = Field(..., description="Product name")
    stockOnHand: int = Field(..., description="Current stock level")
    lowStockThreshold: int = Field(..., description="Low stock threshold")
    timestamp: str = Field(..., description="Event timestamp")


class CriticalStockEvent(BaseModel):
    """Model for critical stock (out of stock) event data."""
    productId: int = Field(..., description="Product identifier")
    productName: str = Field(..., description="Product name")
    productDescription: str = Field(..., description="Product description")
    timestamp: str = Field(..., description="Event timestamp")


class UnpackedDrasiEvent(BaseModel):
    """Model for Drasi unpacked event format."""
    op: str = Field(..., description="Operation type: i (insert), u (update), d (delete), x (control)")
    ts_ms: int = Field(..., description="Timestamp in milliseconds")
    seq: int = Field(..., description="Sequence number")
    payload: Dict[str, Any] = Field(..., description="Event payload containing before/after states")


class NotificationStats(BaseModel):
    """Statistics about processed notifications."""
    low_stock_count: int = Field(0, description="Number of low stock events processed")
    critical_stock_count: int = Field(0, description="Number of critical stock events processed")
    error_count: int = Field(0, description="Number of processing errors")
    last_low_stock_event: Optional[str] = Field(None, description="Timestamp of last low stock event")
    last_critical_event: Optional[str] = Field(None, description="Timestamp of last critical event")


class NotificationResponse(BaseModel):
    """Response model for notification service status."""
    service: str = Field(..., description="Service name")
    status: str = Field(..., description="Service status")
    stats: NotificationStats = Field(..., description="Notification statistics")


class NotificationStatus:
    """Track notification processing status."""
    def __init__(self):
        self.low_stock_count = 0
        self.critical_stock_count = 0
        self.error_count = 0
        self.last_low_stock_event = None
        self.last_critical_event = None
    
    def get_stats(self) -> NotificationStats:
        """Get current statistics."""
        return NotificationStats(
            low_stock_count=self.low_stock_count,
            critical_stock_count=self.critical_stock_count,
            error_count=self.error_count,
            last_low_stock_event=self.last_low_stock_event,
            last_critical_event=self.last_critical_event
        )
    
    def reset(self):
        """Reset all statistics."""
        self.low_stock_count = 0
        self.critical_stock_count = 0
        self.error_count = 0
        self.last_low_stock_event = None
        self.last_critical_event = None