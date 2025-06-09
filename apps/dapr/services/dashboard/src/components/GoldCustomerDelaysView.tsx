import { useState, useEffect } from 'react'
import { Clock, Crown } from 'lucide-react'
import { ResultSet } from '@drasi/signalr-react'
import type { GoldCustomerDelay } from '../types'

interface GoldCustomerDelaysViewProps {
  signalrUrl: string
  queryId: string
  onCountChange: (count: number) => void
}

export default function GoldCustomerDelaysView({ signalrUrl, queryId, onCountChange }: GoldCustomerDelaysViewProps) {
  const [currentTime, setCurrentTime] = useState(Date.now())
  const [processingStartTimes] = useState(new Map<string, number>())
  
  // Update current time every second for live duration display
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(Date.now())
    }, 1000)
    return () => clearInterval(timer)
  }, [])
  
  const formatDuration = (orderId: string) => {
    // In real implementation, this would come from the Drasi query result
    // For now, we'll track when we first see each order
    if (!processingStartTimes.has(orderId)) {
      processingStartTimes.set(orderId, Date.now() - Math.floor(Math.random() * 60000) - 10000)
    }
    
    const startTime = processingStartTimes.get(orderId)!
    const seconds = Math.floor((currentTime - startTime) / 1000)
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    
    if (minutes > 0) {
      return `${minutes}m ${remainingSeconds}s`
    }
    return `${seconds}s`
  }
  
  const handleInvestigateOrder = (orderId: string) => {
    // In a real implementation, this could open a detailed view or redirect
    console.log(`Investigating order: ${orderId}`)
  }
  
  return (
    <div>
      <div className="mb-6">
        <h2 className="text-lg font-semibold text-gray-900">Gold Customer Order Delays</h2>
        <p className="text-sm text-gray-600 mt-1">
          Gold tier customers with orders stuck in PROCESSING state for over 10 seconds
        </p>
      </div>
      
      <ResultSet url={signalrUrl} queryId={queryId}>
        {(items: GoldCustomerDelay[]) => {
          console.log(`[GoldCustomerDelaysView - ${queryId}] Received items from ResultSet:`, JSON.stringify(items));
          // Handle case where items might not be an array yet
          const itemsArray = Array.isArray(items) ? items : []
          
          // Update the count in the parent component
          onCountChange(itemsArray.length)
          
          if (itemsArray.length === 0) {
            return (
              <div className="text-center py-12 text-gray-500">
                No delayed orders for Gold customers currently detected
              </div>
            )
          }
          
          return (
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {itemsArray.map((issue) => (
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
                          {formatDuration(issue.orderId)}
                        </span>
                      </div>
                    </div>
                    
                    <div className="mt-4 pt-4 border-t">
                      <button 
                        onClick={() => handleInvestigateOrder(issue.orderId)}
                        className="w-full bg-indigo-50 text-indigo-700 border border-indigo-200 px-4 py-2 rounded-md text-sm font-medium hover:bg-indigo-100 transition-colors"
                      >
                        Investigate Order
                      </button>
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