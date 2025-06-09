import React, { useState, useEffect } from 'react';
import { ShoppingCart, Package, AlertTriangle, Clock, Crown, TrendingUp, Users, Box, RefreshCw, XCircle, Send } from 'lucide-react';

const DrasiDashboard = () => {
  const [activeTab, setActiveTab] = useState('stock');
  const [stockIssues, setStockIssues] = useState([]);
  const [goldCustomerIssues, setGoldCustomerIssues] = useState([]);
  const [currentTime, setCurrentTime] = useState(Date.now());

  // Update current time every second for live duration display
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(Date.now());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Mock data for demonstration
  useEffect(() => {
    // Simulating real-time data
    setStockIssues([
      {
        orderId: 'ORD-2024-001',
        customerId: 'CUST-101',
        orderStatus: 'PAID',
        items: [
          { productId: 'PROD-A1', productName: 'Premium Laptop', quantity: 5, stockOnHand: 3 },
          { productId: 'PROD-B2', productName: 'Wireless Mouse', quantity: 10, stockOnHand: 2 }
        ]
      },
      {
        orderId: 'ORD-2024-002',
        customerId: 'CUST-102',
        orderStatus: 'PENDING',
        items: [
          { productId: 'PROD-C3', productName: 'USB-C Hub', quantity: 3, stockOnHand: 1 }
        ]
      },
      {
        orderId: 'ORD-2024-003',
        customerId: 'CUST-103',
        orderStatus: 'PAID',
        items: [
          { productId: 'PROD-D4', productName: 'Mechanical Keyboard', quantity: 2, stockOnHand: 0 }
        ]
      }
    ]);

    setGoldCustomerIssues([
      {
        orderId: 'ORD-2024-004',
        customerId: 'CUST-201',
        customerName: 'Alexandra Chen',
        customerEmail: 'a.chen@example.com',
        loyaltyTier: 'GOLD',
        orderStatus: 'PROCESSING',
        processingStartTime: Date.now() - 45000 // Started 45 seconds ago
      },
      {
        orderId: 'ORD-2024-005',
        customerId: 'CUST-202',
        customerName: 'Marcus Johnson',
        customerEmail: 'm.johnson@example.com',
        loyaltyTier: 'GOLD',
        orderStatus: 'PROCESSING',
        processingStartTime: Date.now() - 23000 // Started 23 seconds ago
      }
    ]);
  }, []);

  const getStockSeverity = (quantity, stockOnHand) => {
    const shortage = quantity - stockOnHand;
    if (stockOnHand === 0) return 'critical';
    if (shortage >= quantity * 0.5) return 'high';
    return 'medium';
  };

  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'critical': return 'bg-red-100 border-red-300 text-red-900';
      case 'high': return 'bg-orange-100 border-orange-300 text-orange-900';
      case 'medium': return 'bg-yellow-100 border-yellow-300 text-yellow-900';
      default: return 'bg-gray-100 border-gray-300';
    }
  };

  const formatDuration = (startTime) => {
    const seconds = Math.floor((currentTime - startTime) / 1000);
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return `${minutes}m ${remainingSeconds}s`;
    }
    return `${seconds}s`;
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center">
              <TrendingUp className="h-8 w-8 text-indigo-600 mr-3" />
              <h1 className="text-2xl font-bold text-gray-900">Drasi Live Monitoring</h1>
            </div>
            <div className="flex items-center space-x-4">
              <div className="flex items-center text-sm text-gray-500">
                <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></div>
                Real-time updates active
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-6">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            <button
              onClick={() => setActiveTab('stock')}
              className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeTab === 'stock'
                  ? 'border-indigo-500 text-indigo-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center">
                <Package className="w-5 h-5 mr-2" />
                Stock Risk Orders
                <span className="ml-2 bg-red-100 text-red-600 px-2 py-1 rounded-full text-xs font-semibold">
                  {stockIssues.length}
                </span>
              </div>
            </button>
            <button
              onClick={() => setActiveTab('gold')}
              className={`py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                activeTab === 'gold'
                  ? 'border-indigo-500 text-indigo-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <div className="flex items-center">
                <Crown className="w-5 h-5 mr-2" />
                Gold Customer Delays
                <span className="ml-2 bg-yellow-100 text-yellow-700 px-2 py-1 rounded-full text-xs font-semibold">
                  {goldCustomerIssues.length}
                </span>
              </div>
            </button>
          </nav>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 pb-12">
        {activeTab === 'stock' && (
          <div>
            <div className="mb-6">
              <h2 className="text-lg font-semibold text-gray-900">Orders at Risk - Insufficient Stock</h2>
              <p className="text-sm text-gray-600 mt-1">
                Orders in PAID or PENDING state with products having insufficient stock
              </p>
            </div>

            <div className="grid gap-6">
              {stockIssues.map((order) => (
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
                            : 'bg-blue-100 text-blue-800'
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
                          <div key={idx} className={`border rounded-lg p-3 ${getSeverityColor(severity)}`}>
                            <div className="flex items-center justify-between gap-4">
                              <div className="flex-1">
                                <div className="flex items-center justify-between mb-2">
                                  <div className="flex items-center gap-3">
                                    <h4 className="font-medium">{item.productName}</h4>
                                    <span className="text-sm text-gray-600">({item.productId})</span>
                                  </div>
                                  <AlertTriangle className="w-4 h-4 flex-shrink-0" />
                                </div>
                                <div className="flex items-center gap-6 text-sm">
                                  <div className="flex items-center gap-1">
                                    <span className="text-gray-600">Ordered:</span>
                                    <span className="font-semibold">{item.quantity}</span>
                                  </div>
                                  <div className="flex items-center gap-1">
                                    <span className="text-gray-600">Stock:</span>
                                    <span className="font-semibold">{item.stockOnHand}</span>
                                  </div>
                                  <div className="flex items-center gap-1">
                                    <span className="text-gray-600">Short:</span>
                                    <span className="font-bold text-red-600">-{item.quantity - item.stockOnHand}</span>
                                  </div>
                                  <button className="ml-auto flex items-center space-x-1 px-2 py-1 bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 rounded text-xs font-medium transition-colors">
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
            </div>
          </div>
        )}

        {activeTab === 'gold' && (
          <div>
            <div className="mb-6">
              <h2 className="text-lg font-semibold text-gray-900">Gold Customer Order Delays</h2>
              <p className="text-sm text-gray-600 mt-1">
                Gold tier customers with orders stuck in PROCESSING state for over 10 seconds
              </p>
            </div>

            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {goldCustomerIssues.map((issue) => (
                <div key={issue.orderId} className="bg-white rounded-lg shadow-md overflow-hidden border-2 border-yellow-300">
                  <div className="bg-gradient-to-r from-yellow-400 to-yellow-500 px-4 py-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <Crown className="w-5 h-5 text-white" />
                        <span className="text-white font-semibold">Gold Customer</span>
                      </div>
                      <Clock className="w-5 h-5 text-white" />
                    </div>
                  </div>
                  
                  <div className="p-4">
                    <div className="mb-4">
                      <h3 className="text-lg font-semibold text-gray-900">{issue.customerName}</h3>
                      <p className="text-sm text-gray-600">{issue.customerEmail}</p>
                    </div>
                    
                    <div className="space-y-3">
                      <div className="flex justify-between items-center">
                        <span className="text-sm text-gray-600">Order ID</span>
                        <span className="text-sm font-medium">{issue.orderId}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-sm text-gray-600">Customer ID</span>
                        <span className="text-sm font-medium">{issue.customerId}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-sm text-gray-600">Status</span>
                        <span className="px-2 py-1 bg-orange-100 text-orange-700 rounded text-xs font-semibold">
                          {issue.orderStatus}
                        </span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-sm text-gray-600">Stuck Duration</span>
                        <span className="text-sm font-bold text-red-600 tabular-nums">
                          {formatDuration(issue.processingStartTime)}
                        </span>
                      </div>
                    </div>
                    
                    <div className="mt-4 pt-4 border-t">
                      <button className="w-full bg-indigo-50 text-indigo-700 border border-indigo-200 px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-100 transition-colors">
                        Investigate Order
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>


    </div>
  );
};

export default DrasiDashboard;