import { useEffect, useState } from 'react'
import { ResultSet } from '@drasi/signalr-react'
import { AlertTriangle } from 'lucide-react'
import type { StockIssueItem } from '../types'

interface StockRiskViewProps {
  signalrUrl: string
  queryId: string
  onCountChange: (count: number) => void
}

export default function StockRiskView({ signalrUrl, queryId, onCountChange }: StockRiskViewProps) {
  // State to hold the count of items, updated via a workaround.
  const [itemCount, setItemCount] = useState(0);

  useEffect(() => {
    onCountChange(itemCount);
  }, [itemCount, onCountChange]);

  // Workaround: renderedItemCount is used by RenderWatcher to update itemCount.
  let renderedItemCount = 0;

  return (
    <div className="bg-white shadow-md rounded-lg p-6">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-semibold text-gray-700 flex items-center">
          <AlertTriangle className="w-6 h-6 mr-2 text-red-500" />
          At-Risk Stock Orders
        </h2>
      </div>
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Order ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Customer ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Product</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Quantity Ordered</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Stock on Hand</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            <ResultSet url={signalrUrl} queryId={queryId}>
              {(item: StockIssueItem) => {
                renderedItemCount++;
                return (
                  <tr key={`${item.orderId}-${item.productId}`} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{item.orderId}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{item.customerId}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{item.productName} ({item.productId})</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">{item.quantity}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-red-500 text-center">{item.stockOnHand}</td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        item.orderStatus === 'PENDING' ? 'bg-yellow-100 text-yellow-800' : 
                        item.orderStatus === 'PAID' ? 'bg-blue-100 text-blue-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        {item.orderStatus}
                      </span>
                    </td>
                  </tr>
                );
              }}
            </ResultSet>
          </tbody>
        </table>
        {/* RenderWatcher helps update itemCount based on rendered items. This is a workaround. */}
        <RenderWatcher onRender={() => {
          if (itemCount !== renderedItemCount) {
            setItemCount(renderedItemCount);
          }
        }} />
      </div>
    </div>
  );
}

// Helper component to detect when ResultSet finishes rendering its children for a cycle.
const RenderWatcher = ({ onRender }: { onRender: () => void }) => {
  useEffect(() => {
    onRender();
  });
  return null;
};