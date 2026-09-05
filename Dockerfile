# Multi-stage build for getsaga.dev static site

# Stage 1: Build environment
FROM swift:6.1-noble AS builder

# Install system dependencies
RUN apt-get update && apt-get --no-install-recommends install -y \
    just \
    curl \
    nodejs npm \
    && apt-get install -y libjavascriptcoregtk-4.1-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pkg-config --libs javascriptcoregtk-4.1

# Install pnpm
RUN npm install -g pnpm@10

# Set working directory
WORKDIR /app

# Install Node dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Copy Swift package files for dependency resolution
COPY Package.swift Package.resolved justfile ./

# Pre-fetch Swift dependencies (cached unless Package files change).
# .build is a cache mount so SwiftPM's incremental state survives between
# deploys. Unlike the other Saga sites, the binary isn't copied out of the
# mount: the build step needs .build itself (the Saga checkout for
# copy-docs/symbol-graph, and `swift run`), so the mount is repeated on
# every Swift-touching step instead.
RUN --mount=type=cache,target=/app/.build,sharing=locked \
    just resolve

# Copy source code for compilation
COPY Sources ./Sources

# Pre-build Swift binary (cached unless source or deps change)
RUN --mount=type=cache,target=/app/.build,sharing=locked \
    just compile

# Copy all remaining files
COPY . .

# Build the site
RUN --mount=type=cache,target=/app/.build,sharing=locked \
    --mount=type=cache,target=/root/.swifttailwind \
    just build

# Stage 2: Nginx runtime
FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static files from builder
COPY --from=builder /app/deploy /usr/share/nginx/html
