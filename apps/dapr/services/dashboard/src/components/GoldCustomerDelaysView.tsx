import { useEffect, useState } from 'react'
import { ResultSet } from '@drasi/signalr-react'
import { UserCheck, Clock } from 'lucide-react'
import type { GoldCustomerDelay } from '../types'

interface GoldCustomerDelaysViewProps {
  signalrUrl: string
  queryId: string
  onCountChange: (count: number) => void
}

// Helper function to calculate and format elapsed time (can remain top-level)
const calculateElapsedTime = (waitingSinceISO: string, currentTime: number): string => {
  if (!waitingSinceISO) {
    return 'N/A';
  }
  const waitingSinceTime = new Date(waitingSinceISO).getTime();

  if (isNaN(waitingSinceTime) || waitingSinceTime > currentTime) {
    return 'N/A';
  }
  const seconds = Math.floor((currentTime - waitingSinceTime) / 1000);
  return `${seconds}s`;
};

// New component for individual ticking rows
interface TickingGoldCustomerDelayRowProps {
  item: GoldCustomerDelay;
}

const TickingGoldCustomerDelayRow = ({ item }: TickingGoldCustomerDelayRowProps) => {
  const [elapsedTime, setElapsedTime] = useState(calculateElapsedTime(item.waitingSince, window.Date.now()));

  useEffect(() => {
    const timerId = setInterval(() => {
      setElapsedTime(calculateElapsedTime(item.waitingSince, window.Date.now()));
    }, 1000);
    // Clear interval on component unmount or if item.waitingSince changes
    return () => clearInterval(timerId);
  }, [item.waitingSince]); // Dependency array ensures effect re-runs if the item itself changes

  return (
    <tr className="hover:bg-gray-50">
      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{item.orderId}</td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{item.customerName} ({item.customerId})</td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{item.customerEmail}</td>
      <td className="px-6 py-4 whitespace-nowrap text-sm">
        <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
          item.orderStatus === 'PROCESSING' ? 'bg-orange-100 text-orange-800' :
          'bg-gray-100 text-gray-800'
        }`}>
          {item.orderStatus}
        </span>
      </td>
      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{elapsedTime}</td>
    </tr>
  );
};


export default function GoldCustomerDelaysView({ signalrUrl, queryId, onCountChange }: GoldCustomerDelaysViewProps) {
  const [itemCount, setItemCount] = useState(0);
  let renderedItemCount = 0; // Workaround for counting items

  useEffect(() => {
    onCountChange(itemCount);
  }, [itemCount, onCountChange]);

  // Removed currentTime state and its associated useEffect from here

  return (
    <div className="bg-white shadow-md rounded-lg p-6">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-semibold text-gray-700 flex items-center">
          <UserCheck className="w-6 h-6 mr-2 text-yellow-500" />
          Delayed Gold Customer Orders
        </h2>
      </div>
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Order ID</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Customer Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider flex items-center">
                <Clock className="w-4 h-4 mr-1" /> Waiting Time
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            <ResultSet url={signalrUrl} queryId={queryId}>
              {(item: GoldCustomerDelay) => {
                renderedItemCount++;
                // Use the new TickingGoldCustomerDelayRow component
                // The key prop is important here for React's list reconciliation
                return <TickingGoldCustomerDelayRow key={item.orderId} item={item} />;
              }}
            </ResultSet>
          </tbody>
        </table>
        <RenderWatcher onRender={() => {
          if (itemCount !== renderedItemCount) {
            setItemCount(renderedItemCount);
          }
        }} />
      </div>
    </div>
  );
}

const RenderWatcher = ({ onRender }: { onRender: () => void }) => {
  useEffect(() => {
    onRender();
  });
  return null;
};