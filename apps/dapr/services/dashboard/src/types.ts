export interface StockIssueItem {
  orderId: string
  customerId: string
  orderStatus: string
  productId: string
  stockOnHand: number
  quantity: number
}

export interface GoldCustomerDelay {
  orderId: string
  customerId: string
  customerName: string
  customerEmail: string
  loyaltyTier: string
  orderStatus: string
}