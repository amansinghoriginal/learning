import axios from 'axios'
import { config } from '../config'

const API_BASE_URL = config.apiBaseUrl

export const productsApi = {
  incrementStock: async (productId: string, quantity: number) => {
    try {
      // First get the current product
      const response = await axios.get(`${API_BASE_URL}/products-service/products/${productId}`)
      const currentStock = response.data.stock_on_hand || 0
      
      // Update with increased stock
      await axios.put(`${API_BASE_URL}/products-service/products/${productId}`, {
        ...response.data,
        stock_on_hand: currentStock + quantity
      })
      
      return { success: true }
    } catch (error) {
      console.error('Error incrementing stock:', error)
      return { success: false, error }
    }
  }
}

export const ordersApi = {
  cancelOrder: async (orderId: string) => {
    try {
      // Get current order
      const response = await axios.get(`${API_BASE_URL}/orders-service/orders/${orderId}`)
      
      // Update status to CANCELLED
      await axios.put(`${API_BASE_URL}/orders-service/orders/${orderId}`, {
        ...response.data,
        status: 'CANCELLED'
      })
      
      return { success: true }
    } catch (error) {
      console.error('Error cancelling order:', error)
      return { success: false, error }
    }
  }
}