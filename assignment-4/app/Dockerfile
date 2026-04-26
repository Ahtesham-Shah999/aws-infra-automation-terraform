# ─────────────────────────────────────────────────────────────────────────────
# Task 5 – Multi-stage Dockerfile
# Stage 1: builder  – installs ALL deps and runs the build
# Stage 2: runtime  – copies only production artefacts, runs as non-root user
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: builder ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Copy manifests first to leverage layer caching
COPY package*.json ./

# Install ALL dependencies (including devDeps for tests)
RUN npm ci

# Copy application source
COPY src/ ./src/

# ── Stage 2: runtime ─────────────────────────────────────────────────────────
FROM node:20-alpine AS runtime

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only production manifests and install production deps only
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy application source from builder (no build tools come with it)
COPY --from=builder /app/src ./src

# Own the workdir
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/index.js"]
