import { useState } from 'react'
import { ShoppingCart, AlertTriangle, RefreshCw, XCircle } from 'lucide-react'
import { ResultSet } from '@drasi/signalr-react'
import { productsApi, ordersApi } from '../services/api'
import type { StockIssueItem } from '../types'

interface StockRiskViewProps {
  signalrUrl: string
  queryId: string
  onCountChange: (count: number) => void
}

interface ProcessedOrder {
  orderId: string
  customerId: string
  orderStatus: string
  items: Array<{
    productId: string
    quantity: number
    stockOnHand: number
  }>
}

export default function StockRiskView({ signalrUrl, queryId, onCountChange }: StockRiskViewProps) {
  const [processingActions, setProcessingActions] = useState<Set<string>>(new Set())
  
  const processOrders = (items: StockIssueItem[]): ProcessedOrder[] => {
    const orderMap = new Map<string, ProcessedOrder>()
    
    items.forEach(item => {
      if (!orderMap.has(item.orderId)) {
        orderMap.set(item.orderId, {
          orderId: item.orderId,
          customerId: item.customerId,
          orderStatus: item.orderStatus,
          items: []
        })
      }
      
      const order = orderMap.get(item.orderId)!
      order.items.push({
        productId: item.productId,
        quantity: item.quantity,
        stockOnHand: item.stockOnHand
      })
    })
    
    return Array.from(orderMap.values())
  }
  
  const getStockSeverity = (quantity: number, stockOnHand: number) => {
    const shortage = quantity - stockOnHand
    if (stockOnHand === 0) return 'critical'
    if (shortage >= quantity * 0.5) return 'high'
    return 'medium'
  }
  
  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'bg-red-100 border-red-300 text-red-900'
      case 'high': return 'bg-orange-100 border-orange-300 text-orange-900'
      case 'medium': return 'bg-yellow-100 border-yellow-300 text-yellow-900'
      default: return 'bg-gray-100 border-gray-300'
    }
  }
  
  const handleBackorder = async (productId: string, shortage: number) => {
    const actionKey = `backorder-${productId}`
    setProcessingActions(prev => new Set(prev).add(actionKey))
    
    try {
      const result = await productsApi.incrementStock(productId, shortage)
      if (result.success) {
        console.log(`Successfully backordered ${shortage} units of ${productId}`)
      } else {
        console.error('Failed to backorder:', result.error)
      }
    } finally {
      setProcessingActions(prev => {
        const next = new Set(prev)
        next.delete(actionKey)
        return next
      })
    }
  }
  
  const handleCancelOrder = async (orderId: string) => {
    const actionKey = `cancel-${orderId}`
    setProcessingActions(prev => new Set(prev).add(actionKey))
    
    try {
      const result = await ordersApi.cancelOrder(orderId)
      if (result.success) {
        console.log(`Successfully cancelled order ${orderId}`)
      } else {
        console.error('Failed to cancel order:', result.error)
      }
    } finally {
      setProcessingActions(prev => {
        const next = new Set(prev)
        next.delete(actionKey)
        return next
      })
    }
  }
  
  // Mock product names - in real app, this would come from the product service
  const getProductName = (productId: string) => {
    const names: Record<string, string> = {
      'PROD-A1': 'Premium Laptop',
      'PROD-B2': 'Wireless Mouse',
      'PROD-C3': 'USB-C Hub',
      'PROD-D4': 'Mechanical Keyboard'
    }
    return names[productId] || productId
  }
  
  return (
    <div>
      <div className="mb-6">
        <h2 className="text-lg font-semibold text-gray-900">Orders at Risk - Insufficient Stock</h2>
        <p className="text-sm text-gray-600 mt-1">
          Orders in PAID or PENDING state with products having insufficient stock
        </p>
      </div>
      
      <ResultSet url={signalrUrl} queryId={queryId}>
        {(items: StockIssueItem[]) => {
          console.log(`[StockRiskView - ${queryId}] Received items from ResultSet:`, JSON.stringify(items));
          
          // Handle case where items might not be an array yet
          const itemsArray = Array.isArray(items) ? items : []
          const orders = processOrders(itemsArray)
          
          // Update the count in the parent component
          const uniqueOrders = new Set(itemsArray.map(item => item.orderId))
          onCountChange(uniqueOrders.size)
          
          if (orders.length === 0) {
            return (
              <div className="text-center py-12 text-gray-500">
                No at-risk orders currently detected
              </div>
            )
          }
          
          return (
            <div className="grid gap-6">
              {orders.map((order) => (
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
                        <button 
                          onClick={() => handleCancelOrder(order.orderId)}
                          disabled={processingActions.has(`cancel-${order.orderId}`)}
                          className="flex items-center space-x-1 px-3 py-1 border border-gray-300 bg-white hover:bg-gray-50 text-gray-700 rounded-md text-sm font-medium transition-colors disabled:opacity-50"
                        >
                          <XCircle className="w-4 h-4" />
                          <span>{order.orderStatus === 'PAID' ? 'Cancel & Refund' : 'Cancel & Notify'}</span>
                        </button>
                      </div>
                    </div>
                  </div>
                  
                  <div className="p-6">
                    <div className="space-y-4">
                      {order.items.map((item, idx) => {
                        const severity = getStockSeverity(item.quantity, item.stockOnHand)
                        const shortage = item.quantity - item.stockOnHand
                        
                        return (
                          <div key={idx} className={`border rounded-lg p-3 ${getSeverityColor(severity)}`}>
                            <div className="flex items-center justify-between gap-4">
                              <div className="flex-1">
                                <div className="flex items-center justify-between mb-2">
                                  <div className="flex items-center gap-3">
                                    <h4 className="font-medium">{getProductName(item.productId)}</h4>
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
                                    <span className="font-bold text-red-600">-{shortage}</span>
                                  </div>
                                  <button 
                                    onClick={() => handleBackorder(item.productId, shortage)}
                                    disabled={processingActions.has(`backorder-${item.productId}`)}
                                    className="ml-auto flex items-center space-x-1 px-2 py-1 bg-blue-50 hover:bg-blue-100 text-blue-700 border border-blue-200 rounded text-xs font-medium transition-colors disabled:opacity-50"
                                  >
                                    <RefreshCw className="w-3 h-3" />
                                    <span>Backorder</span>
                                  </button>
                                </div>
                              </div>
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )
        }}
      </ResultSet>
    </div>
  )
}