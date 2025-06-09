import { useState } from 'react'
import { TrendingUp, Package, Crown } from 'lucide-react'
import ConnectionStatus from './ConnectionStatus'
import StockRiskView from './StockRiskView'
import GoldCustomerDelaysView from './GoldCustomerDelaysView'
import { config } from '../config'

export default function Dashboard() {
  const [activeTab, setActiveTab] = useState<'stock' | 'gold'>('stock')
  const [stockCount, setStockCount] = useState(0)
  const [goldCount, setGoldCount] = useState(0)
  
  const { signalrUrl, stockQueryId, goldQueryId } = config
  
  if (!signalrUrl) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-red-600">Error: VITE_SIGNALR_URL environment variable is not set</div>
      </div>
    )
  }
  
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
            <ConnectionStatus url={signalrUrl} />
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
                  {stockCount}
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
                  {goldCount}
                </span>
              </div>
            </button>
          </nav>
        </div>
      </div>
      
      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 pb-12">
        {activeTab === 'stock' && (
          <StockRiskView 
            signalrUrl={signalrUrl} 
            queryId={stockQueryId}
            onCountChange={setStockCount}
          />
        )}
        
        {activeTab === 'gold' && (
          <GoldCustomerDelaysView 
            signalrUrl={signalrUrl} 
            queryId={goldQueryId}
            onCountChange={setGoldCount}
          />
        )}
      </div>
    </div>
  )
}