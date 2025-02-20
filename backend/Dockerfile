# syntax=docker/dockerfile:1.7-labs

# Stage 1: Build the application
FROM node:20-alpine AS build

WORKDIR /usr/src/app

# Copy package files first for better caching
COPY package*.json ./

# Install all dependencies including dev dependencies for build
RUN --mount=type=cache,target=/root/.npm \
    npm install

# Copy the rest of the application
COPY . .

# Create public directory and default files during build
RUN mkdir -p public/settings && \
    echo '{"name":"TicketZap","short_name":"TicketZap","start_url":"/","display":"standalone","theme_color":"#000000","background_color":"#ffffff"}' > public/manifest.json && \
    echo '{"value":"#2196f3"}' > public/settings/primaryColorLight.json && \
    echo '{"value":""}' > public/settings/appLogoLight.json && \
    echo '{"value":"light"}' > public/settings/theme.json

# Build the application
RUN npm run build

# Stage 2: Create the final image without source files
FROM node:20-alpine

WORKDIR /usr/src/app

# Install required tools
RUN apk add --no-cache wget curl postgresql-client

# Copy only the necessary build artifacts from the build stage
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/public ./public

# Create necessary directories with correct permissions
RUN mkdir -p /usr/src/app/private && \
    chown -R node:node /usr/src/app

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Expose the application port
EXPOSE 3000

# Switch to non-root user
USER node

# Create a startup script
COPY --chown=node:node <<EOF /usr/src/app/docker-entrypoint.sh
#!/bin/sh
set -e

echo "Waiting for database..."
# Wait for database using pg_isready
timeout=60
while ! pg_isready -h "\${DB_HOST}" -p "\${DB_PORT}" -U "\${DB_USER}" >/dev/null 2>&1 && [ \$timeout -gt 0 ]; do
  echo "Database is unavailable - sleeping"
  timeout=\$((timeout-1))
  sleep 1
done

if [ \$timeout -le 0 ]; then
  echo "Database connection timeout"
  exit 1
fi

echo "Database is up - running migrations"
npx sequelize db:migrate --config dist/config/database.js --migrations-path dist/database/migrations

echo "Starting application..."
exec node dist/server.js
EOF

# Make the entrypoint script executable
RUN chmod +x /usr/src/app/docker-entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/usr/src/app/docker-entrypoint.sh"]
