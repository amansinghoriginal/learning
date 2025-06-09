# Drasi Dashboard UI Implementation Specification

## Overview

This document specifies the implementation details for a real-time monitoring dashboard for Drasi continuous queries. The dashboard displays two monitoring scenarios:
1. **Stock Risk Orders** - Orders at risk due to insufficient inventory
2. **Gold Customer Delays** - Gold tier customers with orders stuck in processing

## Tech Stack & Dependencies

### Required Packages
```json
{
  "dependencies": {
    "react": "^18.0.0",
    "lucide-react": "^0.263.1",
    "tailwindcss": "^3.0.0"
  }
}
```

### Icon Library
The dashboard uses `lucide-react` for all icons. Import required icons:
```javascript
import { ShoppingCart, Package, AlertTriangle, Clock, Crown, TrendingUp, RefreshCw, XCircle } from 'lucide-react';
```

## Dashboard Structure

### Main Layout
- Single-page application with tab-based navigation
- Header with branding and real-time status indicator
- Tab navigation bar with badge counters
- Content area that switches based on active tab
- No footer or summary section

### Color Scheme
- Primary: Indigo (`indigo-600`)
- Success: Green
- Warning: Yellow/Orange
- Error: Red
- Neutral: Gray shades

## Component Implementation

### 1. Header Component
```jsx
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
```

**Key Features:**
- Pulsing green dot with `animate-pulse` class
- Fixed height header (h-16)
- Max width container for consistent spacing

### 2. Tab Navigation
```jsx
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
</nav>
```

**Key Features:**
- Active tab indicated by indigo border and text
- Badge counters showing issue counts
- Smooth transitions on hover/active states

### 3. Stock Risk Orders Dashboard

#### Order Card Structure
```jsx
<div className="bg-white rounded-lg shadow-md overflow-hidden">
  {/* Order Header */}
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
  
  {/* Product Items */}
  <div className="p-6">
    <div className="space-y-4">
      {/* Product cards go here */}
    </div>
  </div>
</div>
```

#### Product Card (Compact Version)
```jsx
<div className={`border rounded-lg p-3 ${getSeverityColor(severity)}`}>
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
```

#### Severity Color Logic
```javascript
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
```

### 4. Gold Customer Delays Dashboard

#### Customer Card Structure
```jsx
<div className="bg-white rounded-lg shadow-md overflow-hidden border-2 border-yellow-300">
  {/* Gold Header */}
  <div className="bg-gradient-to-r from-yellow-400 to-yellow-500 px-4 py-3">
    <div className="flex items-center justify-between">
      <div className="flex items-center space-x-2">
        <Crown className="w-5 h-5 text-white" />
        <span className="text-white font-semibold">Gold Customer</span>
      </div>
      <Clock className="w-5 h-5 text-white" />
    </div>
  </div>
  
  {/* Customer Details */}
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
```

#### Live Duration Timer
```javascript
// Update timer every second
useEffect(() => {
  const timer = setInterval(() => {
    setCurrentTime(Date.now());
  }, 1000);
  return () => clearInterval(timer);
}, []);

// Format duration function
const formatDuration = (startTime) => {
  const seconds = Math.floor((currentTime - startTime) / 1000);
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  if (minutes > 0) {
    return `${minutes}m ${remainingSeconds}s`;
  }
  return `${seconds}s`;
};
```

**Important:** Use `tabular-nums` class on duration display for stable number rendering.

## State Management

### Required State Variables
```javascript
const [activeTab, setActiveTab] = useState('stock');
const [stockIssues, setStockIssues] = useState([]);
const [goldCustomerIssues, setGoldCustomerIssues] = useState([]);
const [currentTime, setCurrentTime] = useState(Date.now());
```

### Data Structure - Stock Issues
```javascript
{
  orderId: 'ORD-2024-001',
  customerId: 'CUST-101',
  orderStatus: 'PAID', // or 'PENDING'
  items: [
    {
      productId: 'PROD-A1',
      productName: 'Premium Laptop',
      quantity: 5,
      stockOnHand: 3
    }
  ]
}
```

### Data Structure - Gold Customer Issues
```javascript
{
  orderId: 'ORD-2024-004',
  customerId: 'CUST-201',
  customerName: 'Alexandra Chen',
  customerEmail: 'a.chen@example.com',
  loyaltyTier: 'GOLD',
  orderStatus: 'PROCESSING',
  processingStartTime: Date.now() - 45000 // timestamp when entered PROCESSING
}
```

## Styling Guidelines

### Button Styles
1. **Subtle Action Buttons**:
   - Cancel buttons: White background with gray border
   - Backorder buttons: Light blue background (`bg-blue-50`)
   - Investigate buttons: Light indigo background (`bg-indigo-50`)
   - All use hover states for better interactivity

2. **Layout Spacing**:
   - Use consistent padding: `p-3` for compact cards, `p-4` or `p-6` for larger sections
   - Gap utilities for flex layouts: `gap-4`, `gap-6`
   - Margin between sections: `mt-6`, `mt-8`

3. **Typography**:
   - Headers: `text-lg font-semibold`
   - Labels: `text-sm text-gray-600`
   - Values: `text-sm font-medium` or `font-semibold`
   - Critical values: `font-bold text-red-600`

### Responsive Design
- Cards use grid layout on larger screens: `grid gap-4 md:grid-cols-2 lg:grid-cols-3`
- Max width container: `max-w-7xl mx-auto`
- Responsive padding: `px-4 sm:px-6 lg:px-8`

## Implementation Notes

1. **Real-time Updates**: 
   - The dashboard should connect to SignalR websockets for live data
   - Update `stockIssues` and `goldCustomerIssues` arrays when new data arrives
   - Duration timer updates every second independently

2. **Performance Considerations**:
   - Use React.memo for product cards if rendering many items
   - Consider virtualization for very long lists
   - Optimize re-renders by proper state management

3. **Accessibility**:
   - All buttons have hover states
   - Color coding is supplemented with text/icons
   - Proper semantic HTML structure

4. **Edge Cases**:
   - Handle empty states when no issues exist
   - Consider loading states during initial data fetch
   - Error handling for failed SignalR connections

This specification provides the complete UI implementation details. The actual data fetching and SignalR integration should be implemented separately based on your Drasi Reactions setup.