import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  base: '/notifications-service/ui/',
  build: {
    outDir: 'dist'
  },
  server: {
    port: 3000,
    proxy: {
      '/notifications-service/ws': {
        target: 'ws://localhost:8000',
        ws: true,
        rewrite: (path) => path.replace('/notifications-service', '')
      },
      '/notifications-service/api': {
        target: 'http://localhost:8000',
        rewrite: (path) => path.replace('/notifications-service/api', '')
      }
    }
  }
})