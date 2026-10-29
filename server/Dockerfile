# ==============================================================================
# ResQAI Backend - Multi-Stage Production Dockerfile for Render / Linux Container
# ==============================================================================

# Stage 1: Build stage (Node.js 22+ required for better-sqlite3@13.0.3)
FROM node:22-alpine AS builder

WORKDIR /app

# Install native compilation dependencies for node-gyp / better-sqlite3
RUN apk add --no-cache python3 make g++

# Copy package manifests and install all dependencies
COPY package*.json ./
RUN npm ci

# Copy TypeScript config and source code, then compile to dist/
COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

# ==============================================================================
# Stage 2: Runtime stage
# ==============================================================================
FROM node:22-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV PORT=5000

# Install native build tools for compiling better-sqlite3 in production,
# plus libstdc++ runtime library for executing compiled C++ addons
RUN apk add --no-cache python3 make g++ libstdc++

# Copy package manifests and install production dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Copy compiled JavaScript output and SQLite schema definitions
COPY --from=builder /app/dist ./dist
COPY src/db/schema.sql ./src/db/schema.sql
COPY src/db/schema.sql ./dist/db/schema.sql

# Persistent data directory for SQLite database with WAL mode
RUN mkdir -p /app/data
VOLUME ["/app/data"]

EXPOSE 5000

# Start compiled server on 0.0.0.0:$PORT
CMD ["node", "dist/server.js"]
