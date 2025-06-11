# Drasi SignalR Integration Guide

## Overview

This document captures learnings from analyzing the Drasi SignalR reaction components and the delivery dashboard implementation. It serves as a guide for building real-time dashboards using Drasi's SignalR React components.

## Key Components

### 1. @drasi/signalr-react Package

The official Drasi SignalR React library provides two main components:

#### ResultSet Component
- **Purpose**: Displays real-time query results with automatic updates
- **Key Props**:
  - `url` (required): SignalR hub endpoint (e.g., 'http://localhost:8080/hub')
  - `queryId` (required): The Drasi query ID to subscribe to
  - `children`: Render function or React nodes for each item
  - `sortBy`: Function to sort items
  - `reverse`: Boolean to reverse order
  - `ignoreDeletes`: Boolean to ignore delete notifications
  - `onChange`: Callback for change notifications

#### ReactionListener Class
- **Purpose**: Lower-level class for programmatic change handling
- **Use Case**: Connection status monitoring, custom change processing

### 2. Architecture Patterns

#### Connection Management
- Automatic connection pooling for efficiency
- Built-in reconnection logic
- Connection status monitoring capability

#### Real-time Data Flow
1. Drasi queries continuously monitor data sources
2. SignalR reaction broadcasts changes to connected clients
3. ResultSet component maintains synchronized state
4. UI updates automatically on data changes

#### Type Safety
- Full TypeScript support with exported type definitions
- Strongly typed data interfaces for query results

## Implementation Patterns

### Basic Usage Pattern
```jsx
import { ResultSet } from '@drasi/signalr-react';

function Dashboard() {
  return (
    <ResultSet 
      url="http://localhost:8080/hub" 
      queryId="my-query"
      sortBy={item => item.timestamp}
    >
      {item => (
        <div key={item.id}>
          {/* Render item */}
        </div>
      )}
    </ResultSet>
  );
}
```

### Environment Configuration
```javascript
// Use Vite environment variables
const signalrUrl = import.meta.env.VITE_SIGNALR_URL || 'http://localhost:8080/hub';
const queryId = import.meta.env.VITE_QUERY_ID || 'default-query';
```

### Connection Status Monitoring
```javascript
import { ReactionListener } from '@drasi/signalr-react';

// Create listener for connection monitoring
const listener = new ReactionListener(signalrUrl);
// Monitor connection state changes
```

## Dashboard Structure Best Practices

### 1. Component Organization
```
src/
├── App.tsx              # Main app wrapper
├── Dashboard.tsx        # Primary dashboard container
├── components/
│   ├── Header.tsx      # Dashboard header with status
│   ├── ConnectionStatus.tsx  # SignalR connection indicator
│   └── [Feature]View.tsx     # Feature-specific views
```

### 2. Multiple Query Support
For dashboards with multiple queries (like our at-risk-orders and delayed-gold-orders):
- Use separate ResultSet components for each query
- Implement tab-based navigation between views
- Maintain independent state for each query subscription

### 3. Error Handling
- Check for required environment variables
- Display user-friendly error messages
- Implement fallback UI for connection failures

## Integration with Backend Services

### API Calls for Actions
While Drasi handles real-time data display, action buttons (like Backorder or Cancel) require:
1. Traditional REST API calls to backend services
2. Using axios or fetch for HTTP requests
3. Proper error handling and user feedback
4. Optional: Optimistic UI updates

### Service Discovery
- Use environment variables for service endpoints
- Consider using a common base URL for all services
- Implement proper CORS handling

## Build and Deployment Considerations

### Dependencies
```json
{
  "dependencies": {
    "@drasi/signalr-react": "^0.1.0",
    "react": "^18.3.1",
    "axios": "^1.6.2",
    "lucide-react": "^0.263.1"
  },
  "devDependencies": {
    "vite": "^5.0.10",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.3.3"
  }
}
```

### Vite Configuration
- Fast development with HMR
- Environment variable support via import.meta.env
- Optimized production builds

### Docker Considerations
- Multi-stage builds for smaller images
- Nginx for serving static files
- Runtime environment variable injection

## Key Takeaways

1. **Simplicity**: Drasi SignalR components abstract away complex real-time logic
2. **Declarative**: ResultSet component provides a declarative API for real-time data
3. **Efficient**: Connection pooling and smart update mechanisms
4. **Type-Safe**: Full TypeScript support throughout
5. **Flexible**: Supports various rendering patterns and customization

## Implementation Checklist

- [ ] Install @drasi/signalr-react package
- [ ] Configure environment variables for SignalR URL and query IDs
- [ ] Create ResultSet components for each Drasi query
- [ ] Implement proper error handling and loading states
- [ ] Add connection status indicator
- [ ] Integrate action buttons with backend APIs
- [ ] Configure build process with Vite
- [ ] Set up Docker container for deployment
- [ ] Create Kubernetes manifests with proper ingress configuration