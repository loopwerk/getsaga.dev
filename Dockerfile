# Multi-stage build for getsaga.dev static site

# Stage 1: Build environment
FROM swift:6.0-noble AS builder

# Install system dependencies
RUN apt-get update && apt-get --no-install-recommends install -y \
    just \
    curl \
    nodejs npm \
    && apt-get install -y libjavascriptcoregtk-4.1-dev \
    && rm -rf /var/lib/apt/lists/* \
    && pkg-config --libs javascriptcoregtk-4.1

# Install pnpm
RUN npm install -g pnpm

# Set working directory
WORKDIR /app

# Install Node dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Copy Swift package files for dependency resolution
COPY Package.swift Package.resolved justfile ./

# Pre-fetch Swift dependencies (cached unless Package files change)
RUN just resolve

# Copy source code and justfile for compilation
COPY Sources ./Sources

# Pre-build Swift binary (cached unless source or deps change)
RUN just compile

# Copy all remaining files
COPY . .

# Build the site
RUN --mount=type=cache,target=/root/.swifttailwind \
    just build

# Stage 2: Nginx runtime
FROM nginx:alpine

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built static files from builder
COPY --from=builder /app/deploy /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
