FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code and build
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

FROM node:20-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=5000

# Copy package definition and install production dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy compiled files and schema assets
COPY --from=builder /app/dist ./dist
COPY src/db/schema.sql ./src/db/schema.sql
COPY src/db/schema.sql ./dist/db/schema.sql

# Persistent data directory for SQLite WAL
RUN mkdir -p /app/data
VOLUME ["/app/data"]

EXPOSE 5000

CMD ["node", "dist/server.js"]

