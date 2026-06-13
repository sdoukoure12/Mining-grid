FROM node:18-alpine

# Install curl for health checks
RUN apk add --no-cache curl

WORKDIR /app

# Install dependencies first (layer caching)
COPY package*.json ./
RUN npm ci --omit=dev

# Copy application source
COPY . .

# Create non-root user
RUN addgroup -S miner && adduser -S miner -G miner
USER miner

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl -sf http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]
