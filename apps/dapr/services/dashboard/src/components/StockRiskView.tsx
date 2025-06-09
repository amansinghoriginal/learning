import { useEffect, useState, useRef } from 'react';
import { ResultSet } from '@drasi/signalr-react';
import { ShoppingCart, AlertTriangle, RefreshCw, XCircle } from 'lucide-react';
import type { StockIssueItem } from '../types';

interface GroupedStockOrder {
  orderId: string;
  customerId: string;
  orderStatus: string;
  items: StockIssueItem[];
}

interface StockRiskViewProps {
  signalrUrl: string;
  queryId: string;
  onCountChange: (count: number) => void;
}

// Helper functions from spec
const getStockSeverity = (quantity: number, stockOnHand: number) => {
  if (stockOnHand < 0) stockOnHand = 0; // Ensure stock on hand isn't negative for calculation
  const shortage = quantity - stockOnHand;
  if (stockOnHand === 0 && quantity > 0) return 'critical';
  if (shortage > 0 && shortage >= quantity * 0.5) return 'high';
  if (shortage > 0) return 'medium';
  return 'low'; // Or some default if not a risk
};

const getSeverityColor = (severity: string) => {
  switch (severity) {
    case 'critical': return 'bg-red-100 border-red-300 text-red-700';
    case 'high': return 'bg-orange-100 border-orange-300 text-orange-700';
    case 'medium': return 'bg-yellow-100 border-yellow-300 text-yellow-700';
    default: return 'bg-gray-100 border-gray-300 text-gray-700';
  }
};

export default function StockRiskView({ signalrUrl, queryId, onCountChange }: StockRiskViewProps) {
  const [processedOrders, setProcessedOrders] = useState<GroupedStockOrder[]>([]);
  const currentRawItemsRef = useRef<StockIssueItem[]>([]);

  // This effect will process the collected items after ResultSet is done for a cycle
  const processAndSetOrders = () => {
    const rawItems = [...currentRawItemsRef.current];
    currentRawItemsRef.current = []; // Reset for next render cycle

    const grouped = new Map<string, GroupedStockOrder>();

    rawItems.forEach(item => {
      if (!grouped.has(item.orderId)) {
        grouped.set(item.orderId, {
          orderId: item.orderId,
          customerId: item.customerId,
          orderStatus: item.orderStatus,
          items: [],
        });
      }
      // Ensure item is only added if it represents a stock risk
      if (item.quantity > item.stockOnHand) {
         grouped.get(item.orderId)!.items.push(item);
      }
    });
    
    // Filter out orders that no longer have at-risk items after the above check
    const newProcessedOrders = Array.from(grouped.values()).filter(order => order.items.length > 0);

    setProcessedOrders(newProcessedOrders);
    onCountChange(newProcessedOrders.length);
  };


  if (!queryId) {
    return <div>Error: Stock Query ID is not configured.</div>;
  }
  
  return (
    <div>
      <div className="mb-6">
        <h2 className="text-lg font-semibold text-gray-900">Orders at Risk - Insufficient Stock</h2>
        <p className="text-sm text-gray-600 mt-1">
          Orders in PAID or PENDING state with products having insufficient stock.
        </p>
      </div>

      <div className="grid gap-6">
        {processedOrders.map((order) => (
          <div key={order.orderId} className="bg-white rounded-lg shadow-md overflow-hidden">
            <div className="px-6 py-4 border-b bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <ShoppingCart className="w-5 h-5 text-gray-600" />
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900">{order.orderId}</h3>
                    <p className="text-sm text-gray-600">Customer: {order.customerId}</p>
                  </div>
                </div>
                <div className="flex items-center space-x-3">
                  <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                    order.orderStatus === 'PAID' 
                      ? 'bg-green-100 text-green-800' 
                      : order.orderStatus === 'PENDING' 
                      ? 'bg-blue-100 text-blue-800'
                      : 'bg-gray-100 text-gray-800' // Default/other statuses
                  }`}>
                    {order.orderStatus}
                  </span>
                  <button className="flex items-center space-x-1 px-3 py-1 border border-gray-300 bg-white hover:bg-gray-50 text-gray-700 rounded-md text-sm font-medium transition-colors">
                    <XCircle className="w-4 h-4" />
                    <span>{order.orderStatus === 'PAID' ? 'Cancel & Refund' : 'Cancel & Notify'}</span>
                  </button>
                </div>
              </div>
            </div>
            
            <div className="p-6">
              <div className="space-y-4">
                {order.items.map((item, idx) => {
                  const severity = getStockSeverity(item.quantity, item.stockOnHand);
                  return (
                    <div key={`${item.productId}-${idx}`} className={`border rounded-lg p-3 ${getSeverityColor(severity)}`}>
                      <div className="flex items-center justify-between gap-4">
                        <div className="flex-1">
                          <div className="flex items-center justify-between mb-1">
                            <div className="flex items-center gap-3">
                              <h4 className="font-medium text-sm">{item.productName}</h4>
                              <span className="text-xs text-gray-500">({item.productId})</span>
                            </div>
                            <AlertTriangle className="w-4 h-4 flex-shrink-0" />
                          </div>
                          <div className="flex items-center gap-4 text-xs">
                            <div className="flex items-center gap-1">
                              <span className="text-gray-500">Ordered:</span>
                              <span className="font-semibold">{item.quantity}</span>
                            </div>
                            <div className="flex items-center gap-1">
                              <span className="text-gray-500">Stock:</span>
                              <span className="font-semibold">{item.stockOnHand < 0 ? 0 : item.stockOnHand}</span>
                            </div>
                            <div className="flex items-center gap-1">
                              <span className="text-gray-500">Short:</span>
                              <span className="font-bold text-red-600">
                                {item.quantity - (item.stockOnHand < 0 ? 0 : item.stockOnHand)}
                              </span>
                            </div>
                            <button className="ml-auto flex items-center space-x-1 px-2 py-1 bg-blue-50 hover:bg-blue-100 text-blue-600 border border-blue-200 rounded text-xs font-medium transition-colors">
                              <RefreshCw className="w-3 h-3" />
                              <span>Backorder</span>
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        ))}
        {processedOrders.length === 0 && (
            <div className="text-center py-10 text-gray-500">
                No stock risk orders at the moment.
            </div>
        )}
      </div>
      <ResultSet url={signalrUrl} queryId={queryId}>
        {(item: StockIssueItem) => {
          currentRawItemsRef.current.push(item);
          return null; // This component doesn't render UI directly from ResultSet
        }}
      </ResultSet>
      {/* RenderWatcher to trigger processing after ResultSet updates */}
      <RenderWatcher onRender={processAndSetOrders} />
    </div>
  );
}

// Helper component to detect when ResultSet finishes rendering its children for a cycle.
// This is still a workaround.
const RenderWatcher = ({ onRender }: { onRender: () => void }) => {
  useEffect(() => {
    // Call onRender after the current render cycle is complete
    const timeoutId = setTimeout(onRender, 0);
    return () => clearTimeout(timeoutId);
  }, [onRender]); // Re-run if onRender changes, though it should be stable
  return null;
};