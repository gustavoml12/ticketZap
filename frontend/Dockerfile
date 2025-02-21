FROM node:20-alpine as build-deps

# Set environment variables for better performance
ENV NODE_ENV=production
ENV DISABLE_ESLINT_PLUGIN=true
ENV GENERATE_SOURCEMAP=false
ENV CI=false

# Add build dependencies
RUN apk add --no-cache python3 make g++

WORKDIR /usr/src/app

# Copy only package files first
COPY package*.json ./

# Install dependencies with minimal resource usage
RUN --mount=type=cache,target=/root/.npm \
    npm ci --prefer-offline --no-audit --production=false \
    && npm cache clean --force

# Copy only necessary files
COPY . .

# Build with minimal memory usage
RUN npm run build:prod

# Production environment
FROM ghcr.io/ticketz-oss/nginx-alpine:latest

WORKDIR /var/www/public

# Copy built assets
COPY --from=build-deps /usr/src/app/build/ .
COPY --from=build-deps /usr/src/app/node_modules/@socket.io/admin-ui/ui/dist ./socket-admin

# Copy nginx configuration
COPY nginx /etc/nginx

# Create necessary directories and files
RUN mkdir -p public-settings/vector && \
    mkdir -p settings && \
    echo '{"name":"TicketZap","short_name":"TicketZap","start_url":"/","display":"standalone","theme_color":"#000000","background_color":"#ffffff","icons":[{"src":"/vector/favicon.ico","sizes":"64x64 32x32 24x24 16x16","type":"image/x-icon"}]}' > manifest.json && \
    echo '{"value":"#2196f3"}' > public-settings/primaryColorLight.json && \
    echo '{"value":""}' > public-settings/appLogoLight.json && \
    echo '{"value":"light"}' > public-settings/theme.json && \
    echo '{"BACKEND_PROTOCOL":"http","BACKEND_HOST":"backend","BACKEND_PORT":"3000","BACKEND_PATH":""}' > config.json && \
    echo '{"value":"#2196f3"}' > settings/primaryColorLight.json && \
    echo '{"value":""}' > settings/appLogoLight.json && \
    echo '{"value":"light"}' > settings/theme.json && \
    touch public-settings/vector/favicon.ico

# Set proper permissions
RUN chown -R nginx:nginx /var/www/public && \
    chmod -R 755 /var/www/public

ENTRYPOINT ["dumb-init", "--"]
CMD ["nginx", "-g", "daemon off;"]
