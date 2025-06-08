import json
import logging
import os
from typing import Optional, Any
from dapr.clients import DaprClient

logger = logging.getLogger(__name__)


class DaprStateStore:
    def __init__(self, store_name: Optional[str] = None):
        self.store_name = store_name or os.getenv("DAPR_STORE_NAME", "orders-store")
        self.client = DaprClient()
        logger.info(f"Initialized Dapr state store client for store: {self.store_name}")

    async def get_item(self, key: str) -> Optional[dict]:
        """Get an item from the state store."""
        try:
            response = self.client.get_state(
                store_name=self.store_name,
                key=key
            )
            
            if response.data:
                data = json.loads(response.data)
                logger.debug(f"Retrieved item with key '{key}': {data}")
                return data
            else:
                logger.debug(f"No item found with key '{key}'")
                return None
                
        except Exception as e:
            logger.error(f"Error getting item with key '{key}': {str(e)}")
            raise

    async def save_item(self, key: str, data: dict) -> None:
        """Save an item to the state store."""
        try:
            self.client.save_state(
                store_name=self.store_name,
                key=key,
                value=json.dumps(data)
            )
            logger.debug(f"Saved item with key '{key}': {data}")
            
        except Exception as e:
            logger.error(f"Error saving item with key '{key}': {str(e)}")
            raise

    async def delete_item(self, key: str) -> None:
        """Delete an item from the state store."""
        try:
            self.client.delete_state(
                store_name=self.store_name,
                key=key
            )
            logger.debug(f"Deleted item with key '{key}'")
            
        except Exception as e:
            logger.error(f"Error deleting item with key '{key}': {str(e)}")
            raise